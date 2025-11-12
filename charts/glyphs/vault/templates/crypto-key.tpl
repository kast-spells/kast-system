{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

vault.cryptoKey generates cryptographic keypairs and stores them in Vault.
Follows standard glyph parameter pattern: (list $root $glyphDefinition).

Creates a Job using summon workload system that:
- Generates Ed25519 or RSA keypair
- Stores keypair in Vault via API
- Creates VaultSecret to sync keypair to K8s Secret

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: CryptoKey configuration object (index . 1)
  - name: Resource name (required)
  - algorithm: "ed25519" (default) or "rsa"
  - bits: RSA key size (default 4096, only for RSA)
  - domain: Optional domain annotation (stored in Vault for reference)
  - comment: Optional key comment

Example glyph definition:
  vault:
    stalwart-dkim:
      type: cryptoKey
      algorithm: ed25519
      domain: the.yaml.life
      comment: "DKIM for the.yaml.life"

Outputs:
- Vault KV secret at: chapter/<name>
  Keys: private_key, public_key, public_key_base64, algorithm, domain (optional), created_at
- K8s VaultSecret: <name> (syncs from Vault to K8s Secret)
  Keys: private_key, public_key, public_key_base64, algorithm, domain (optional)
- ServiceAccount, Role, RoleBinding (via summon)

Usage with dnsEndpointSourced:
  certManager:
    mail-dkim-record:
      type: dnsEndpointSourced
      sourceSecret: stalwart-dkim  # Read from VaultSecret
      sourceKey: public_key_base64
      dnsRecordFormat: "v=DKIM1; k=ed25519; p=%s"
*/}}

{{- define "vault.cryptoKey" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}
{{- $vaultServer := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.selector) "vault" $root.Values.chapter.name ) | fromJson) "results" }}
{{- $algorithm := default "ed25519" $glyphDefinition.algorithm }}
{{- $bits := default 4096 $glyphDefinition.bits }}
{{- range $vaultConf := $vaultServer }}

{{/* Build script variables */}}
{{- $vaultPath := include "generateSecretPath" ( list $root $glyphDefinition $vaultConf "" ) }}
{{- $keyComment := default (printf "%s@%s" $glyphDefinition.name $root.Release.Namespace) $glyphDefinition.comment }}
{{- $domainParam := "" }}
{{- if $glyphDefinition.domain }}
{{- $domainParam = printf "domain=\"%s\"" $glyphDefinition.domain }}
{{- end }}

{{/* Build keygen script - unified for both algorithms */}}
{{- $keygenScript := "" }}
{{- $keygenCmd := "" }}
{{- $algoName := "" }}
{{- if eq $algorithm "ed25519" }}
{{- $keygenCmd = "ssh-keygen -t ed25519 -f /tmp/key -N \"\"" }}
{{- $algoName = "ed25519" }}
{{- else if eq $algorithm "rsa" }}
{{- $keygenCmd = printf "ssh-keygen -t rsa -b %d -f /tmp/key -N \"\"" $bits }}
{{- $algoName = "rsa" }}
{{- end }}

{{- $domainArg := "" }}
{{- $domainField := "" }}
{{- if $glyphDefinition.domain }}
{{- $domainArg = printf "--arg domain \"%s\"" $glyphDefinition.domain }}
{{- $domainField = ", domain: $domain" }}
{{- end }}

{{- $keygenScript = printf `#!/bin/sh
set -e
echo "Generating %s keypair for %s..."

VAULT_ADDR="%s"
VAULT_PATH="%s"
VAULT_AUTH_PATH="%s"
VAULT_ROLE="%s"
SA_TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"

# Login to Vault using Kubernetes auth
echo "Logging into Vault..."
LOGIN_RESPONSE=$(curl -s -X POST "$VAULT_ADDR/v1/auth/$VAULT_AUTH_PATH/login" \
  -d "{\"jwt\":\"$SA_TOKEN\",\"role\":\"$VAULT_ROLE\"}")

VAULT_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.auth.client_token')

if [ -z "$VAULT_TOKEN" ] || [ "$VAULT_TOKEN" = "null" ]; then
  echo "Failed to login to Vault:"
  echo "$LOGIN_RESPONSE"
  exit 1
fi

echo "Logged in successfully"

# Check if key exists - try KV v2 first, fallback to KV v1
if curl -sf -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/$VAULT_PATH" >/dev/null 2>&1; then
  echo "Key already exists (KV v2), skipping"
  exit 0
fi

# Try KV v1 path
VAULT_PATH_V1=$(echo "$VAULT_PATH" | sed 's|/data/|/|')
if curl -sf -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/$VAULT_PATH_V1" >/dev/null 2>&1; then
  echo "Key already exists (KV v1), skipping"
  exit 0
fi

# Generate keypair
%s -C "%s"

# Build JSON payloads for both KV versions
JSON_V2=$(jq -n \
  --arg pk "$(cat /tmp/key | base64 -w 0)" \
  --arg pubk "$(cat /tmp/key.pub)" \
  --arg pubk64 "$(cat /tmp/key.pub | awk '{print $2}')" \
  --arg created "$(date -u +%%Y-%%m-%%dT%%H:%%M:%%SZ)" \
  %s \
  '{data: {private_key: $pk, public_key: $pubk, public_key_base64: $pubk64, algorithm: "%s"%s, created_at: $created}}')

JSON_V1=$(jq -n \
  --arg pk "$(cat /tmp/key | base64 -w 0)" \
  --arg pubk "$(cat /tmp/key.pub)" \
  --arg pubk64 "$(cat /tmp/key.pub | awk '{print $2}')" \
  --arg created "$(date -u +%%Y-%%m-%%dT%%H:%%M:%%SZ)" \
  %s \
  '{private_key: $pk, public_key: $pubk, public_key_base64: $pubk64, algorithm: "%s"%s, created_at: $created}')

# Try KV v2 first
RESULT=$(curl -s -w "\\n%%{http_code}" -X POST \
  -H "X-Vault-Token: $VAULT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$JSON_V2" "$VAULT_ADDR/v1/$VAULT_PATH")

HTTP_CODE=$(echo "$RESULT" | tail -n1)
BODY=$(echo "$RESULT" | sed '$d')

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "204" ]; then
  echo "Stored in Vault (KV v2): $VAULT_PATH"
else
  echo "KV v2 failed (HTTP $HTTP_CODE): $BODY"
  echo "Trying KV v1..."

  RESULT_V1=$(curl -s -w "\\n%%{http_code}" -X POST \
    -H "X-Vault-Token: $VAULT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$JSON_V1" "$VAULT_ADDR/v1/$VAULT_PATH_V1")

  HTTP_CODE_V1=$(echo "$RESULT_V1" | tail -n1)
  BODY_V1=$(echo "$RESULT_V1" | sed '$d')

  if [ "$HTTP_CODE_V1" = "200" ] || [ "$HTTP_CODE_V1" = "204" ]; then
    echo "Stored in Vault (KV v1): $VAULT_PATH_V1"
  else
    echo "KV v1 failed (HTTP $HTTP_CODE_V1): $BODY_V1"
    exit 1
  fi
fi

echo "Done"
` $algoName $glyphDefinition.name $vaultConf.url $vaultPath (default $root.Values.spellbook.name $vaultConf.authPath) (include "common.name" $root) $keygenCmd $keyComment $domainArg $algoName $domainField $domainArg $algoName $domainField }}

{{/* Build summon-compatible Values for Job */}}
{{- $jobValues := dict
  "name" (printf "%s-keygen" $glyphDefinition.name)
  "workload" (dict
    "enabled" true
    "type" "job"
    "restartPolicy" "OnFailure"
    "backoffLimit" 3
  )
  "serviceAccount" (dict
    "enabled" false
    "name" (include "common.name" $root)
  )
  "service" (dict
    "enabled" false
  )
  "configMaps" (dict
    "keygen-script" (dict
      "location" "create"
      "contentType" "file"
      "mountPath" "/scripts"
      "name" "keygen.sh"
      "content" $keygenScript
    )
  )
  "image" (dict
    "repository" "docker.io/hashicorp"
    "name" "vault"
    "tag" "latest"
    "pullPolicy" "IfNotPresent"
  )
  "command" (list "/bin/sh")
  "args" (list "-c" "apk add --no-cache openssh-client curl jq && /bin/sh /scripts/keygen.sh")
  "envs" (dict
    "VAULT_SKIP_VERIFY" "true"
  )
  "resources" (dict
    "requests" (dict
      "cpu" "100m"
      "memory" "128Mi"
    )
    "limits" (dict
      "cpu" "200m"
      "memory" "256Mi"
    )
  )
  "annotations" (dict
    "helm.sh/hook" "post-install,post-upgrade"
    "helm.sh/hook-weight" "-5"
    "helm.sh/hook-delete-policy" "before-hook-creation"
  )
}}

{{/* Create new root context with job values */}}
{{- $jobRoot := merge (dict "Values" $jobValues) (dict "Release" $root.Release "Chart" $root.Chart) }}

{{/* Generate ServiceAccount using summon */}}
{{- include "summon.serviceAccount" $jobRoot }}

{{/* Generate ConfigMaps */}}
{{- range $name, $content := $jobValues.configMaps }}
  {{- if eq $content.location "create" }}
  {{- $glyph := dict "name" $name "definition" $content  }}
    {{- include "summon.configMap" (list $jobRoot $glyph )  }}
  {{- end }}
{{- end }}

{{/* Generate Job using summon workload system */}}
{{- include "summon.workload.job" $jobRoot }}

{{/* Create VaultSecret to sync private key from Vault to K8s */}}
---
apiVersion: redhatcop.redhat.io/v1alpha1
kind: VaultSecret
metadata:
  name: {{ $glyphDefinition.name }}
  namespace: {{ $root.Release.Namespace }}
  annotations:
    argocd.argoproj.io/sync-options: Prune=false
spec:
  refreshPeriod: {{ default "3m0s" $glyphDefinition.refreshPeriod }}
  vaultSecretDefinitions:
    - name: secret
      requestType: GET
      path: {{ include "generateSecretPath" ( list $root $glyphDefinition $vaultConf "" ) }}
      {{- include "vault.connect" (list $root $vaultConf  "" ( default "" $glyphDefinition.serviceAccount )) | nindent 6 }}
  output:
    name: {{ $glyphDefinition.name }}
    stringData:
      private_key: '{{ `{{ .secret.private_key }}` }}'
      public_key: '{{ `{{ .secret.public_key }}` }}'
      public_key_base64: '{{ `{{ .secret.public_key_base64 }}` }}'
      algorithm: '{{ `{{ .secret.algorithm }}` }}'
      {{- if $glyphDefinition.domain }}
      domain: '{{ `{{ .secret.domain }}` }}'
      {{- end }}
    type: Opaque
{{- end }}
{{- end }}

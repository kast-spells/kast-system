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

{{/* Build keygen script */}}
{{- $keygenScript := "" }}
{{- if eq $algorithm "ed25519" }}
{{- $keygenScript = printf `#!/bin/sh
set -e
echo "Generating ed25519 keypair for %s..."

VAULT_ADDR="%s"
VAULT_PATH="%s"
VAULT_TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"

# Check if key already exists in Vault
if curl -sf -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/$VAULT_PATH" >/dev/null 2>&1; then
  echo "Key already exists in Vault, skipping generation"
  exit 0
fi

# Generate Ed25519 keypair
ssh-keygen -t ed25519 -f /tmp/key -N "" -C "%s"

# Extract key components
PRIVATE_KEY=$(cat /tmp/key | base64 -w 0)
PUBLIC_KEY=$(cat /tmp/key.pub)
PUBLIC_KEY_B64=$(echo "$PUBLIC_KEY" | awk '{print $2}')

echo "Generated keypair successfully"

# Store in Vault using API
echo "Storing keypair in Vault..."
CREATED_AT="$(date -u +%%Y-%%m-%%dT%%H:%%M:%%SZ)"

# Escape JSON strings properly (replace " with \" and \ with \\)
escape_json() {
  echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

PRIVATE_KEY_ESC=$(escape_json "$PRIVATE_KEY")
PUBLIC_KEY_ESC=$(escape_json "$PUBLIC_KEY")
PUBLIC_KEY_B64_ESC=$(escape_json "$PUBLIC_KEY_B64")

# Build JSON payload using jq for proper JSON encoding
if command -v jq >/dev/null 2>&1; then
  JSON_PAYLOAD=$(jq -n \
    --arg pk "$PRIVATE_KEY" \
    --arg pubk "$PUBLIC_KEY" \
    --arg pubk64 "$PUBLIC_KEY_B64" \
    --arg created "$CREATED_AT" \
    %s \
    '{data: {private_key: $pk, public_key: $pubk, public_key_base64: $pubk64, algorithm: "ed25519"%s, created_at: $created}}')
else
  # Fallback to manual JSON construction
  JSON_PAYLOAD=$(cat <<EOF
{
  "data": {
    "private_key": "$PRIVATE_KEY_ESC",
    "public_key": "$PUBLIC_KEY_ESC",
    "public_key_base64": "$PUBLIC_KEY_B64_ESC",
    "algorithm": "ed25519",
    %s
    "created_at": "$CREATED_AT"
  }
}
EOF
)
fi

echo "Vault URL: $VAULT_ADDR/v1/$VAULT_PATH"
echo "Sending request to Vault..."

RESPONSE=$(curl -s -w "\\n%%{http_code}" -X POST \
  -H "X-Vault-Token: $VAULT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD" \
  "$VAULT_ADDR/v1/$VAULT_PATH")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" != "200" ] && [ "$HTTP_CODE" != "204" ]; then
  echo "Error storing keypair in Vault (HTTP $HTTP_CODE)"
  echo "Response: $BODY"
  exit 1
fi

echo "Keypair stored in Vault: $VAULT_PATH"
echo "Done"
` $glyphDefinition.name $vaultConf.url $vaultPath $keyComment (ternary (printf "--arg domain \"%s\"" $glyphDefinition.domain) "" (ne $glyphDefinition.domain nil)) (ternary ", domain: $domain" "" (ne $glyphDefinition.domain nil)) (ternary (printf "\"domain\": \"%s\"," $glyphDefinition.domain) "" (ne $glyphDefinition.domain nil)) }}
{{- else if eq $algorithm "rsa" }}
{{- $keygenScript = printf `#!/bin/sh
set -e
echo "Generating RSA %d keypair for %s..."

VAULT_ADDR="%s"
VAULT_PATH="%s"
VAULT_TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"

# Check if key already exists in Vault
if curl -sf -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/$VAULT_PATH" >/dev/null 2>&1; then
  echo "Key already exists in Vault, skipping generation"
  exit 0
fi

# Generate RSA keypair
ssh-keygen -t rsa -b %d -f /tmp/key -N "" -C "%s"

# Extract key components
PRIVATE_KEY=$(cat /tmp/key | base64 -w 0)
PUBLIC_KEY=$(cat /tmp/key.pub)
PUBLIC_KEY_B64=$(echo "$PUBLIC_KEY" | awk '{print $2}')

echo "Generated keypair successfully"

# Store in Vault using API
echo "Storing keypair in Vault..."
CREATED_AT="$(date -u +%%Y-%%m-%%dT%%H:%%M:%%SZ)"

# Escape JSON strings properly (replace " with \" and \ with \\)
escape_json() {
  echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

PRIVATE_KEY_ESC=$(escape_json "$PRIVATE_KEY")
PUBLIC_KEY_ESC=$(escape_json "$PUBLIC_KEY")
PUBLIC_KEY_B64_ESC=$(escape_json "$PUBLIC_KEY_B64")

# Build JSON payload using jq for proper JSON encoding
if command -v jq >/dev/null 2>&1; then
  JSON_PAYLOAD=$(jq -n \
    --arg pk "$PRIVATE_KEY" \
    --arg pubk "$PUBLIC_KEY" \
    --arg pubk64 "$PUBLIC_KEY_B64" \
    --arg created "$CREATED_AT" \
    %s \
    '{data: {private_key: $pk, public_key: $pubk, public_key_base64: $pubk64, algorithm: "rsa"%s, created_at: $created}}')
else
  # Fallback to manual JSON construction
  JSON_PAYLOAD=$(cat <<EOF
{
  "data": {
    "private_key": "$PRIVATE_KEY_ESC",
    "public_key": "$PUBLIC_KEY_ESC",
    "public_key_base64": "$PUBLIC_KEY_B64_ESC",
    "algorithm": "rsa",
    %s
    "created_at": "$CREATED_AT"
  }
}
EOF
)
fi

echo "Vault URL: $VAULT_ADDR/v1/$VAULT_PATH"
echo "Sending request to Vault..."

RESPONSE=$(curl -s -w "\\n%%{http_code}" -X POST \
  -H "X-Vault-Token: $VAULT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD" \
  "$VAULT_ADDR/v1/$VAULT_PATH")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" != "200" ] && [ "$HTTP_CODE" != "204" ]; then
  echo "Error storing keypair in Vault (HTTP $HTTP_CODE)"
  echo "Response: $BODY"
  exit 1
fi

echo "Keypair stored in Vault: $VAULT_PATH"
echo "Done"
` $bits $glyphDefinition.name $vaultConf.url $vaultPath $bits $keyComment (ternary (printf "--arg domain \"%s\"" $glyphDefinition.domain) "" (ne $glyphDefinition.domain nil)) (ternary ", domain: $domain" "" (ne $glyphDefinition.domain nil)) (ternary (printf "\"domain\": \"%s\"," $glyphDefinition.domain) "" (ne $glyphDefinition.domain nil)) }}
{{- end }}

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
    "enabled" true
    "name" (printf "%s-keygen" $glyphDefinition.name)
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

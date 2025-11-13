{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

certManager.dnsEndpointSourced creates a DNSEndpoint and a Job to populate it from a Vault Secret.
This is needed because DNSEndpoint CRD doesn't support valueFrom/secretRef directly.
Follows standard glyph parameter pattern: (list $root $glyphDefinition).

Creates:
- DNSEndpoint with initial placeholder target
- ServiceAccount, Role, RoleBinding for Job
- Job that reads Secret (from Vault) and updates DNSEndpoint target

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: DNSEndpointSourced configuration object (index . 1)
  - name: DNSEndpoint resource name (optional, defaults to chart name)
  - dnsName: DNS record name (required, e.g., "default._domainkey.the.yaml.life")
  - recordType: DNS record type (default "TXT")
  - sourceSecret: Secret name containing the target value (required)
  - sourceKey: Key in Secret to read (required)
  - dnsRecordFormat: Optional format string (e.g., "v=DKIM1; k=ed25519; p=%s")

Example glyph definition:
  certManager:
    mail-dkim-record:
      type: dnsEndpointSourced
      dnsName: "default._domainkey.the.yaml.life"
      recordType: "TXT"
      sourceSecret: stalwart-dkim
      sourceKey: public_key_base64
      dnsRecordFormat: "v=DKIM1; k=ed25519; p=%s"

Workflow:
1. DNSEndpoint created with placeholder: "PLACEHOLDER_WILL_BE_UPDATED_FROM_VAULT"
2. Job waits for Secret to exist (VaultSecret syncs from Vault)
3. Job reads value from Secret
4. Job formats value if dnsRecordFormat provided
5. Job patches DNSEndpoint with actual value
6. External-DNS picks up the DNSEndpoint and creates DNS record
*/}}

{{- define "certManager.dnsEndpointSourced" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}

{{/* Create DNSEndpoint with placeholder */}}
---
apiVersion: externaldns.k8s.io/v1alpha1
kind: DNSEndpoint
metadata:
  name: {{ default (include "common.name" $root) $glyphDefinition.name }}
  namespace: {{ $root.Release.Namespace }}
spec:
  endpoints:
    - dnsName: {{ $glyphDefinition.dnsName }}
      recordType: {{ default "TXT" $glyphDefinition.recordType }}
      targets:
        - "PLACEHOLDER_WILL_BE_UPDATED_FROM_VAULT"

{{/* Build script for updating DNSEndpoint from Secret */}}
{{- $dnsName := $glyphDefinition.dnsName }}
{{- $sourceSecret := $glyphDefinition.sourceSecret }}
{{- $sourceKey := $glyphDefinition.sourceKey }}
{{- $dnsEndpointName := default (include "common.name" $root) $glyphDefinition.name }}
{{- $recordType := default "TXT" $glyphDefinition.recordType }}
{{- $namespace := $root.Release.Namespace }}
{{- $formatLine := "" }}
{{- if not (empty $glyphDefinition.dnsRecordFormat) }}
{{- $formatLine = printf "DNS_VALUE=$(printf \"%s\" \"$TARGET_VALUE\")\necho \"Formatted DNS record: ${DNS_VALUE:0:80}...\"" $glyphDefinition.dnsRecordFormat }}
{{- else }}
{{- $formatLine = "DNS_VALUE=\"$TARGET_VALUE\"" }}
{{- end }}

{{- $updateScript := printf `#!/bin/bash
set -e
echo "DNSEndpoint Updater for %s"
echo "====================================="

# Wait for Secret to exist (VaultSecret syncs from Vault)
echo "Waiting for Secret %s..."
until kubectl get secret %s -n %s > /dev/null 2>&1; do
  echo "  Secret not found yet, retrying in 5s..."
  sleep 5
done
echo "Secret found!"

# Extract target value from Secret
echo "Reading value from Secret key: %s"
TARGET_VALUE=$(kubectl get secret %s -n %s -o jsonpath='{.data.%s}' | base64 -d)

if [ -z "$TARGET_VALUE" ]; then
  echo "ERROR: Secret key '%s' is empty or doesn't exist"
  exit 1
fi

echo "Raw value (first 80 chars): ${TARGET_VALUE:0:80}..."

# Format DNS record if format string provided
%s

# Patch DNSEndpoint with actual value
echo "Updating DNSEndpoint %s..."
kubectl patch dnsendpoint %s -n %s \
  --type=json \
  -p="[{\"op\": \"replace\", \"path\": \"/spec/endpoints/0/targets/0\", \"value\": \"$DNS_VALUE\"}]"

echo "DNSEndpoint updated successfully!"
echo ""
echo "DNS record will be created by external-dns:"
echo "   Name: %s"
echo "   Type: %s"
echo "   Value: ${DNS_VALUE:0:100}..."
` $dnsName $sourceSecret $sourceSecret $namespace $sourceKey $sourceSecret $namespace $sourceKey $sourceKey $formatLine $dnsEndpointName $dnsEndpointName $namespace $dnsName $recordType }}

{{/* Build summon-compatible Values for Job */}}
{{- $jobValues := dict
  "name" (printf "%s-updater" (default (include "common.name" $root) $glyphDefinition.name))
  "workload" (dict
    "enabled" true
    "type" "job"
    "restartPolicy" "OnFailure"
    "backoffLimit" 5
  )
  "serviceAccount" (dict
    "enabled" true
    "name" (printf "%s-updater" (default (include "common.name" $root) $glyphDefinition.name))
  )
  "service" (dict
    "enabled" false
  )
  "configMaps" (dict
    "updater-script" (dict
      "location" "create"
      "contentType" "file"
      "mountPath" "/scripts"
      "name" "update-dns.sh"
      "content" $updateScript
    )
  )
  "image" (dict
    "repository" "docker.io/bitnami"
    "name" "kubectl"
    "tag" "latest"
    "pullPolicy" "IfNotPresent"
  )
  "command" (list "/bin/bash")
  "args" (list "/scripts/update-dns.sh")
  "resources" (dict
    "requests" (dict
      "cpu" "50m"
      "memory" "64Mi"
    )
    "limits" (dict
      "cpu" "100m"
      "memory" "128Mi"
    )
  )
  "annotations" (dict
    "helm.sh/hook" "post-install,post-upgrade"
    "helm.sh/hook-weight" "0"
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
  {{- end -}}
{{- end -}}

{{/* Generate RBAC resources manually */}}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ printf "%s-updater" (default (include "common.name" $root) $glyphDefinition.name) }}
  namespace: {{ $root.Release.Namespace }}
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get"]
- apiGroups: ["externaldns.k8s.io"]
  resources: ["dnsendpoints"]
  verbs: ["get", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ printf "%s-updater" (default (include "common.name" $root) $glyphDefinition.name) }}
  namespace: {{ $root.Release.Namespace }}
subjects:
- kind: ServiceAccount
  name: {{ printf "%s-updater" (default (include "common.name" $root) $glyphDefinition.name) }}
  namespace: {{ $root.Release.Namespace }}
roleRef:
  kind: Role
  name: {{ printf "%s-updater" (default (include "common.name" $root) $glyphDefinition.name) }}
  apiGroup: rbac.authorization.k8s.io

{{/* Generate Job using summon workload system */}}
{{- include "summon.workload.job" $jobRoot }}

{{- end }}

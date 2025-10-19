{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

s3.seaweed - SeaweedFS S3 infrastructure setup

Creates:
1. EventSource (resource type, watching secrets in seaweedfs namespace)
2. Sensor (triggers aggregator pod on secret changes)
3. ConfigMap (aggregator script)
4. ServiceAccount + RBAC (for aggregator pod)
5. Prolicy (vault access for /s3-identities/*)

The aggregator script:
- Lists all secrets with label kast.io/s3-identity=true
- Reads credentials and metadata
- Builds S3 config JSON
- Creates/updates ConfigMap
- Restarts seaweedfs-s3 deployment
*/}}

{{- define "s3.seaweed.impl" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 -}}
{{- $name := $glyphDefinition.name -}}

{{- /* Find EventBus via runicIndexer (default: book fallback) */}}
{{- $eventBusSelector := default (dict "default" "book") $glyphDefinition.eventBusSelector }}
{{- $eventBuses := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon $eventBusSelector "eventbus" $root.Values.chapter.name) | fromJson) "results" }}

{{- if not $eventBuses }}
  {{- fail "s3.seaweed: No EventBus found. Ensure argo-events is deployed with eventbus lexicon entry." }}
{{- end }}

{{- $eventBus := index $eventBuses 0 }}

{{- /* 1. EventSource - Watching secrets in seaweedfs namespace */}}
{{ include "argo-events.eventSource" (list $root (dict
  "name" (printf "%s-s3-secrets" $name)
  "eventBusName" $eventBus.name
  "resource" (dict
    "s3-identity-changes" (dict
      "namespace" $root.Release.Namespace
      "group" ""
      "version" "v1"
      "resource" "secrets"
      "eventTypes" (list "ADD" "UPDATE" "DELETE")
      "filter" (dict
        "labels" (list
          (dict "key" "kast.io/s3-identity" "operation" "=" "value" "true")
        )
      )
    )
  )
)) }}

{{- /* 2. Aggregator Script ConfigMap */}}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $name }}-s3-aggregator-script
data:
  aggregator.sh: |
    #!/bin/bash
    set -euo pipefail

    echo "🔍 Starting S3 identity aggregation..."

    # Find all S3 identity secrets in current namespace
    SECRETS_JSON=$(kubectl get secrets -n ${NAMESPACE} \
      -l kast.io/s3-identity=true \
      -o json)

    # Count secrets
    SECRET_COUNT=$(echo "$SECRETS_JSON" | jq '.items | length')
    echo "📊 Found $SECRET_COUNT S3 identity secret(s)"

    if [ "$SECRET_COUNT" -eq 0 ]; then
      echo "⚠️  No S3 identities found, creating empty config"
      IDENTITIES="[]"
    else
      # Build identities array from secrets
      IDENTITIES=$(echo "$SECRETS_JSON" | jq -r '
        .items | map({
          name: (.metadata.labels."kast.io/identity-name" // .metadata.name),
          credentials: [{
            accessKey: (.data.AWS_ACCESS_KEY_ID | @base64d),
            secretKey: (.data.AWS_SECRET_ACCESS_KEY | @base64d)
          }],
          actions: ((.data.PERMISSIONS // "UmVhZCxXcml0ZQ==") | @base64d | split(",")),
          buckets: ((.data.BUCKETS // "") | @base64d | split(",") | map(select(length > 0)))
        })
      ')
    fi

    # Build final S3 config
    S3_CONFIG=$(jq -n --argjson identities "$IDENTITIES" '{identities: $identities}')

    echo "📝 Generated S3 config:"
    echo "$S3_CONFIG" | jq .

    # Create/update ConfigMap
    kubectl create configmap seaweedfs-s3-config \
      -n ${NAMESPACE} \
      --from-literal=s3.json="$S3_CONFIG" \
      --dry-run=client -o yaml | \
      kubectl apply -f -

    echo "✅ ConfigMap updated successfully"

    # Restart seaweedfs-s3 deployment to reload config
    echo "🔄 Restarting seaweedfs-s3 deployment..."
    kubectl rollout restart deployment/seaweedfs-s3 -n ${NAMESPACE} || true

    echo "🎉 S3 aggregation complete!"

{{- /* 3. Sensor - Triggers aggregator pod on secret changes */}}
{{ include "argo-events.sensor" (list $root (dict
  "name" (printf "%s-s3-aggregator" $name)
  "eventBusName" $eventBus.name
  "template" (dict
    "serviceAccountName" (printf "%s-s3-aggregator" $name)
  )
  "dependencies" (list
    (dict
      "name" "s3-secret-event"
      "eventSourceName" (printf "%s-s3-secrets" $name)
      "eventName" "s3-identity-changes"
    )
  )
  "triggers" (list
    (dict
      "name" "run-aggregator"
      "type" "k8s"
      "k8s" (dict
        "group" ""
        "version" "v1"
        "resource" "pods"
        "operation" "create"
        "source" (dict
          "resource" (dict
            "apiVersion" "v1"
            "kind" "Pod"
            "metadata" (dict
              "generateName" (printf "%s-s3-aggregator-" $name)
              "namespace" $root.Release.Namespace
            )
            "spec" (dict
              "serviceAccountName" (printf "%s-s3-aggregator-pod" $name)
              "restartPolicy" "Never"
              "containers" (list
                (dict
                  "name" "aggregator"
                  "image" "bitnami/kubectl:latest"
                  "command" (list "/bin/bash" "-c" "source /scripts/aggregator.sh")
                  "env" (list
                    (dict "name" "NAMESPACE" "value" $root.Release.Namespace)
                  )
                  "volumeMounts" (list
                    (dict "name" "script" "mountPath" "/scripts")
                  )
                  "resources" (dict
                    "requests" (dict "cpu" "50m" "memory" "64Mi")
                    "limits" (dict "cpu" "200m" "memory" "128Mi")
                  )
                )
              )
              "volumes" (list
                (dict
                  "name" "script"
                  "configMap" (dict "name" (printf "%s-s3-aggregator-script" $name))
                )
              )
            )
          )
        )
      )
    )
  )
)) }}

{{- /* 4. ServiceAccount + RBAC for Sensor (in EventBus namespace) */}}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ $name }}-s3-aggregator
  namespace: {{ $eventBus.namespace }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ $name }}-s3-sensor
  namespace: {{ $root.Release.Namespace }}
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["create", "get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ $name }}-s3-sensor
  namespace: {{ $root.Release.Namespace }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: {{ $name }}-s3-sensor
subjects:
  - kind: ServiceAccount
    name: {{ $name }}-s3-aggregator
    namespace: {{ $eventBus.namespace }}

{{- /* 5. ServiceAccount + RBAC for aggregator pod (in app namespace) */}}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ $name }}-s3-aggregator-pod
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ $name }}-s3-aggregator-pod
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "list"]
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list", "create", "update", "patch"]
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ $name }}-s3-aggregator-pod
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: {{ $name }}-s3-aggregator-pod
subjects:
  - kind: ServiceAccount
    name: {{ $name }}-s3-aggregator-pod
    namespace: {{ $root.Release.Namespace }}

{{- /* 6. Vault Prolicy for s3-identities access - uses naming convention in /publics/ */}}
{{- $vaultServers := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict (dict)) "vault" $root.Values.chapter.name) | fromJson) "results" }}
{{- $vault := index $vaultServers 0 }}
{{ include "vault.prolicy" (list $root (dict
  "nameOverride" (printf "%s-s3-identities" $name)
  "serviceAccount" (printf "%s-s3-aggregator-pod" $name)
  "extraPolicy" (list
    (dict
      "path" (printf "%s/data/%s/*/publics/s3-identities-%s-*" $vault.secretPath $root.Values.spellbook.name $name)
      "capabilities" (list "read" "list")
    )
    (dict
      "path" (printf "%s/metadata/%s/*/publics/s3-identities-%s-*" $vault.secretPath $root.Values.spellbook.name $name)
      "capabilities" (list "read" "list")
    )
    (dict
      "path" (printf "%s/data/%s/*/*/publics/s3-identities-%s-*" $vault.secretPath $root.Values.spellbook.name $name)
      "capabilities" (list "read" "list")
    )
    (dict
      "path" (printf "%s/metadata/%s/*/*/publics/s3-identities-%s-*" $vault.secretPath $root.Values.spellbook.name $name)
      "capabilities" (list "read" "list")
    )
  )
)) }}

{{- end }}

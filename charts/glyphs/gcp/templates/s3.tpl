{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "gcp.bucket" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: storage.cnrm.cloud.google.com/v1beta1
kind: StorageBucket
metadata:
  name: {{ $glyphDefinition.name  }}
  annotations:
    {{- include "common.infra.annotations" $root | nindent 4}}
  labels:
    {{- include "common.infra.labels" $root | nindent 4 }}
spec:
  location: {{ default "US" $glyphDefinition.location }}
  versioning:
    enabled: {{ default true $glyphDefinition.privateIpGoogleAccess }}
  uniformBucketLevelAccess: {{ default true $glyphDefinition.uniformAccess }}
{{- end }}

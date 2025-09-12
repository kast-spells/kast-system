{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "gcp.gsa" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMServiceAccount
metadata:
  labels:
    {{- include "common.infra.labels" $root | nindent 4}}
  name: {{ default (include "common.name" $root) $glyphDefinition.name }}
  annotations:
    {{- include "common.infra.annotations" $root | nindent 4}}
spec:
  displayName: {{ default $glyphDefinition.name $glyphDefinition.displayName }}
  description: {{ default $glyphDefinition.name $glyphDefinition.description }}
{{- end }}
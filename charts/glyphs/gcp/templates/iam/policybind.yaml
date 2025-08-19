{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "gcp.iamBind" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  labels:
    {{- include "common.infra.labels" $root | nindent 4}}
  name: {{ default (include "common.name" $root) $glyphDefinition.name }}
  annotations:
    {{- include "common.infra.annotations" $root | nindent 4}}
spec:
  member: {{ $glyphDefinition.member }}
  role: {{ $glyphDefinition.role }}
  resourceRef:
    name: {{ $glyphDefinition.resourceRef }}
    {{- if $glyphDefinition.resourceRefExternal }}
    external: {{ $glyphDefinition.resourceRefExternal }}
    {{- end }}
    {{- if $glyphDefinition.resourceRefApiVersion }}
    apiVersion: {{ $glyphDefinition.resourceRefApiVersion }}
    {{- end }}
    {{- if $glyphDefinition.resourceRefNamespace }}
    namespace: {{ $glyphDefinition.resourceRefNamespace }}
    {{- end }}
    {{- if $glyphDefinition.resourceRefKind }}
    kind: {{ $glyphDefinition.resourceRefKind }}
    {{- end }}
{{- end }}

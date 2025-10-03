{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

Tarot Trinket Helper Templates
Dynamic workflow composition using mystical card-based architecture
*/}}

{{/*
Common labels with kast-specific additions
*/}}
{{- define "tarot.labels" -}}
{{ include "common.labels" . }}
kast.io/component: tarot
kast.io/type: trinket
{{- end }}

{{/*
Selector labels - use common glyph
*/}}
{{- define "tarot.selectorLabels" -}}
{{ include "common.selectorLabels" . }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "tarot.serviceAccountName" -}}
{{- if .Values.tarot.serviceAccount.name }}
{{- .Values.tarot.serviceAccount.name }}
{{- else if .Values.serviceAccount.name }}
{{- .Values.serviceAccount.name }}
{{- else }}
{{- include "common.name" . }}
{{- end }}
{{- end }}

{{/*
Generate workflow name
*/}}
{{- define "tarot.workflowName" -}}
{{- if and .Values.tarot.generateName (not .Values.tarot.asTemplate) }}
{{- printf "%s-" (include "common.name" .) }}
{{- else }}
{{- include "common.name" . }}
{{- end }}
{{- end }}

{{/*
Resolve template values (supports {{envs.VAR}}, {{secrets.NAME.key}}, {{workflow.parameters.param}})
*/}}
{{- define "tarot.resolveValue" -}}
{{- $root := index . 0 -}}
{{- $value := index . 1 -}}
{{- if typeIs "string" $value -}}
  {{- if contains "{{envs." $value -}}
    {{/* Environment variable resolution */}}
    {{- $envPattern := "{{envs.([^}]+)}}" -}}
    {{- $envVar := regexFind $envPattern $value | regexReplaceAll "{{envs\\." "" | regexReplaceAll "}}" "" -}}
    {{- if hasKey $root.Values.envs $envVar -}}
      {{- $value | replace (printf "{{envs.%s}}" $envVar) (index $root.Values.envs $envVar) -}}
    {{- else -}}
      {{- $value -}}
    {{- end -}}
  {{- else if contains "{{secrets." $value -}}
    {{/* Secret resolution */}}
    {{- $secretPattern := "{{secrets\\.([^.]+)\\.([^}]+)}}" -}}
    {{- $matches := regexFindAll $secretPattern $value -1 -}}
    {{- $result := $value -}}
    {{- range $matches -}}
      {{- $secretName := regexReplaceAll "{{secrets\\." . "" | regexReplaceAll "\\..*}}" "" -}}
      {{- $secretKey := regexReplaceAll ".*\\." . "" | regexReplaceAll "}}" "" -}}
      {{- if hasKey $root.Values.secrets $secretName -}}
        {{- $secret := index $root.Values.secrets $secretName -}}
        {{- $result = $result | replace . (printf "secret-value-%s-%s" $secretName $secretKey) -}}
      {{- end -}}
    {{- end -}}
    {{- $result -}}
  {{- else if contains "{{workflow.parameters." $value -}}
    {{/* Workflow parameter resolution */}}
    {{- $value -}}
  {{- else -}}
    {{- $value -}}
  {{- end -}}
{{- else -}}
  {{- $value -}}
{{- end -}}
{{- end -}}

{{/*
Get secret name for a secret definition
*/}}
{{- define "tarot.getSecretName" -}}
{{- $root := index . 0 -}}
{{- $secretDef := index . 1 -}}
{{- if eq $secretDef.type "k8s-secret" -}}
  {{- $secretDef.name -}}
{{- else if eq $secretDef.type "vault-secret" -}}
  {{- printf "%s-vault-secret" (include "common.name" $root) -}}
{{- else -}}
  {{- printf "%s-secret" (include "common.name" $root) -}}
{{- end -}}
{{- end -}}


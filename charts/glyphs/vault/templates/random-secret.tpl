{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "vault.randomSecret" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
{{- $vaultServer := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.selector) "vault" $root.Values.chapter.name ) | fromJson) "results" }}
{{- range $vaultConf := $vaultServer }}
---
apiVersion: redhatcop.redhat.io/v1alpha1
kind: RandomSecret
metadata:
  name: {{ $glyphDefinition.name }}
  labels:
    {{- include "common.all.labels" $root | nindent 4 }}
    {{- with $glyphDefinition.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $glyphDefinition.annotations }}
  annotations:
    {{- include "common.annotations" $root | nindent 4 }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- include "vault.connect" (list $root $vaultConf "" ( default "" $glyphDefinition.serviceAccount )) | nindent 2 }}
  isKVSecretsEngineV2: true
  path: {{ include "generateSecretPath" ( list $root $glyphDefinition $vaultConf "true" ) }}
  secretKey: {{ default "password" $glyphDefinition.randomKey }}
  secretFormat:
    passwordPolicyName: {{ default "simple-password-policy" $glyphDefinition.passPolicyName }}
  {{- if $glyphDefinition.refreshPeriod }}
  refreshPeriod: {{ $glyphDefinition.refreshPeriod }}
  {{- end }}
  {{- end }}
{{- end }}
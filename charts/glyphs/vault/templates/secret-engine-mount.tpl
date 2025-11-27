{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

vault.secretEngineMount creates SecretEngineMount resources for Vault secret engines.
Follows standard glyph parameter pattern: (list $root $glyphDefinition).

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: Mount configuration object (index . 1)
  - mountType: Engine type (required: "database", "pki", "kv", etc.)
  - path: Mount path (optional, defaults based on mountType)
  - description: Human-friendly description
  - config: Mount configuration overrides (optional)
  - options: Mount type-specific options (optional)
  - serviceAccount: ServiceAccount for Vault auth (optional)

Default Paths by mountType:
- database: "database-{book}-{chapter}"
- pki: "pki-{book}-{chapter}"
- kv: "kv-{book}-{chapter}"
- Custom: Use explicit path parameter

Example glyph definition:
  vault:
    - type: secretEngineMount
      mountType: database
      path: database-mybook-prod
      description: "Database secrets engine for dynamic credentials"
*/}}

{{- define "vault.secretEngineMount" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}
{{- $vaultServer := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.selector) "vault" $root.Values.chapter.name ) | fromJson) "results" }}
{{- range $vaultConf := $vaultServer }}
{{- $mountType := required "mountType is required for secretEngineMount" $glyphDefinition.mountType }}
{{- $defaultPath := "" }}
{{- if eq $mountType "database" }}
  {{- $defaultPath = printf "database-%s-%s" $root.Values.spellbook.name $root.Values.chapter.name }}
{{- else if eq $mountType "pki" }}
  {{- $defaultPath = printf "pki-%s-%s" $root.Values.spellbook.name $root.Values.chapter.name }}
{{- else if eq $mountType "kv" }}
  {{- $defaultPath = printf "kv-%s-%s" $root.Values.spellbook.name $root.Values.chapter.name }}
{{- else }}
  {{- $defaultPath = printf "%s-%s-%s" $mountType $root.Values.spellbook.name $root.Values.chapter.name }}
{{- end }}
{{- $mountPath := default $defaultPath $glyphDefinition.path }}
---
apiVersion: redhatcop.redhat.io/v1alpha1
kind: SecretEngineMount
metadata:
  name: {{ $mountPath }}
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
  {{- include "vault.connect" (list $root $vaultConf "" (default "" $glyphDefinition.serviceAccount)) | nindent 2 }}
  type: {{ $mountType }}
  path: {{ $mountPath }}
  {{- if $glyphDefinition.description }}
  description: {{ $glyphDefinition.description | quote }}
  {{- else }}
  description: "{{ $mountType | title }} secrets engine for {{ $root.Values.spellbook.name }}/{{ $root.Values.chapter.name }}"
  {{- end }}
  {{- if $glyphDefinition.config }}
  config:
    {{- toYaml $glyphDefinition.config | nindent 4 }}
  {{- end }}
  {{- if $glyphDefinition.options }}
  options:
    {{- toYaml $glyphDefinition.options | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}

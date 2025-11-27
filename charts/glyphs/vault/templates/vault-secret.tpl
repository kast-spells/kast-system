{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

vault.secret creates ExternalSecret resources for HashiCorp Vault integration.
Follows standard glyph parameter pattern: (list $root $glyphDefinition).

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: Secret configuration object (index . 1)

Generation Types:
- generationType: "kv" (default) - KV v2 secrets, uses /data/ prefix
- generationType: "database" - Database dynamic credentials, requires databaseEngine and databaseRole

Path Resolution Examples (KV secrets):

path: "chapter" → /$spellbook/$chapter/publics/$secretName
path: "book" → /$spellbook/publics/$secretName
path: "/custom/path" → /custom/path/$secretName (absolute)
path: "summon" → /$spellbook/$chapter/$summonName/publics/$secretName

Database Credentials Example:

glyphs:
  vault:
    - type: secret
      name: myapp-db-creds
      generationType: "database"
      databaseEngine: "postgres"      # Name of postgres entry in lexicon
      databaseRole: "read-write"      # or "read-only"
      path: "chapter"                 # Optional, defaults to "chapter"
      format: env
      serviceAccount: myapp
      refreshPeriod: 30m
      keys:
        - username
        - password

Generates path: {secretPath}/{book}/{chapter}/publics/{databaseEngine}/creds/{databaseEngine}-{databaseRole}
Example: secret/mybook/prod/publics/postgres/creds/postgres-read-write

KV Secret Example:

glyphs:
  vault:
    - type: secret
      name: api-credentials
      format: env
      path: "chapter"
      keys:
        - api-key
        - api-secret

*/}}

{{- define "vault.secret" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}
{{- $vaultServer := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.selector) "vault" $root.Values.chapter.name ) | fromJson) "results" }}
{{- range $vaultConf := $vaultServer }}
{{- if ne false $glyphDefinition.random }}
  {{- if $glyphDefinition.randomKeys }}
    {{- range $keyName := $glyphDefinition.randomKeys }}
{{ include "vault.randomSecret" (list $root (merge (dict "randomKey" $keyName "name" (printf "%s-%s" $glyphDefinition.name ($keyName | lower | replace "_" "-"))) $glyphDefinition) ) }}
    {{- end }}
  {{- else if or $glyphDefinition.randomKey $glyphDefinition.random }}
{{ include "vault.randomSecret" (list $root $glyphDefinition ) }}
  {{- end }}
{{- end }}
---
apiVersion: redhatcop.redhat.io/v1alpha1
kind: VaultSecret
metadata:
  name: {{ $glyphDefinition.name }}
  {{- if $glyphDefinition.namespace }}
  namespace: {{ $glyphDefinition.namespace }}
  {{- end }}
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
  refreshPeriod: {{ default "3m0s" $glyphDefinition.refreshPeriod }}
  vaultSecretDefinitions:
  {{- if $glyphDefinition.randomKeys }}
    {{- range $keyName := $glyphDefinition.randomKeys }}
    - name: {{ $keyName | lower | replace "_" "-" }}
      requestType: GET
      path: {{ include "generateSecretPath" (list $root (dict "name" (printf "%s-%s" $glyphDefinition.name ($keyName | lower | replace "_" "-")) "path" $glyphDefinition.path) $vaultConf "") }}
      {{- if $glyphDefinition.customRole }}
      {{- include "vault.connect" (list $root $vaultConf "" (default "" $glyphDefinition.serviceAccount) $glyphDefinition.customRole) | nindent 6 }}
      {{- else }}
      {{- include "vault.connect" (list $root $vaultConf "" (default "" $glyphDefinition.serviceAccount)) | nindent 6 }}
      {{- end }}
    {{- end }}
  {{- else }}
    - name: secret
      requestType: GET
      {{- $generationType := default "kv" $glyphDefinition.generationType }}
      {{- if eq $generationType "database" }}
      {{- $engineName := required "databaseEngine is required when generationType=database" $glyphDefinition.databaseEngine }}
      {{- $roleName := required "databaseRole is required when generationType=database" $glyphDefinition.databaseRole }}
      {{- $databaseMount := default (printf "database-%s-%s" $root.Values.spellbook.name $root.Values.chapter.name) $glyphDefinition.databaseMount }}
      path: {{ $databaseMount }}/creds/{{ $engineName }}-{{ $roleName }}
      {{- else }}
      path: {{ include "generateSecretPath" ( list $root $glyphDefinition $vaultConf "" ) }}
      {{- end }}
      {{- if $glyphDefinition.customRole }}
      {{- include "vault.connect" (list $root $vaultConf "" (default "" $glyphDefinition.serviceAccount) $glyphDefinition.customRole) | nindent 6 }}
      {{- else }}
      {{- include "vault.connect" (list $root $vaultConf "" (default "" $glyphDefinition.serviceAccount)) | nindent 6 }}
      {{- end }}
  {{- end }}
  output:
    name: {{ default $glyphDefinition.name $glyphDefinition.nameOverwrite }}
    labels:
      {{- include "common.all.labels" $root | nindent 6 }}
      {{- with $glyphDefinition.labels }}
      {{- toYaml . | nindent 6 }}
      {{- end }}
    annotations:
      {{- include "common.annotations" $root | nindent 6 }}
      {{- with $glyphDefinition.annotations }}
      {{- toYaml . | nindent 6 }}
      {{- end }}
    stringData:
    {{- $format := default "plain" $glyphDefinition.format }}
    {{- if eq $format "env" }} #tiene q haber una forma de hacer q esto funcione con un range del lado del operator para q no hagan falta las keys
      {{- range $key := $glyphDefinition.keys }}
        {{ upper $key | replace "-" "_" }}: '{{ default (printf `{{ .secret.%s }}` $key ) }}'
      {{- end }}
      {{-  if $glyphDefinition.staticData }}
        {{- range $static, $data := $glyphDefinition.staticData }}
        {{ upper $static | replace "-" "_" }}: {{ $data }}
        {{- end }}
      {{- end }}
      {{- if $glyphDefinition.randomKeys }}
        {{- range $keyName := $glyphDefinition.randomKeys }}
        {{ upper $keyName | replace "-" "_" }}: '{{ printf `{{ index . "%s" "%s" }}` ($keyName | lower | replace "_" "-") $keyName }}'
        {{- end }}
      {{- else if $glyphDefinition.randomKey }}
        {{ upper $glyphDefinition.randomKey | replace "-" "_" }}: '{{ printf `{{ .secret.%s }}` $glyphDefinition.randomKey  }}'
      {{- else if $glyphDefinition.random }}
        PASSWORD: '{{ printf `{{ .secret.password }}` }}'
      {{- end }}
    {{- else if eq $format "json" }}
      {{ default $glyphDefinition.name $glyphDefinition.key }}: '{{ `{{ .secret | toJson  }}` }}'
    {{- else if eq $format "b64" }}
      {{ default $glyphDefinition.name $glyphDefinition.key }}: '{{ `{{ .secret.b64 }}` }}'
    {{- else if eq $format "yaml" }}
      {{ default $glyphDefinition.name $glyphDefinition.key }}: '{{ `{{ .secret | toYaml  }}` }}'
    {{- else if eq $format "plain" }}
      {{- range $key := default list $glyphDefinition.keys }}
        {{ $key  }}: '{{ default (printf `{{ .secret.%s }}` $key ) }}'
      {{- end }}
      {{-  if $glyphDefinition.staticData }}
        {{- range $static, $data := $glyphDefinition.staticData }}
        {{ $static }}: {{ $data }}
        {{- end }}
      {{- end }}
      {{- if $glyphDefinition.randomKeys }}
        {{- range $keyName := $glyphDefinition.randomKeys }}
        {{ $keyName }}: '{{ printf `{{ index . "%s" "%s" }}` ($keyName | lower | replace "_" "-") $keyName }}'
        {{- end }}
      {{- else if $glyphDefinition.randomKey }}
        {{ $glyphDefinition.randomKey  }}: '{{ printf `{{ index .secret "%s" }}` $glyphDefinition.randomKey  }}'
      {{- else if and $glyphDefinition.random (not $glyphDefinition.randomKey) }}
        password: '{{ printf `{{ .secret.password }}` }}'
      {{- end }}
    {{- end }}
    type: {{ default "Opaque" $glyphDefinition.secretType }}
{{- end }}
{{- end }}
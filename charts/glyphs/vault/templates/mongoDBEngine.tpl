{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

vault.mongoDBEngine creates MongoDB DatabaseSecretEngineConfig and roles for HashiCorp Vault.
Follows standard glyph parameter pattern: (list $root $glyphDefinition).

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: Database engine configuration object (index . 1)

Example glyph definition:
  vault:
    - type: mongoDBEngine
      name: mongodb
      mongoSelector:
        app: my-app

Lexicon mongodb entry can specify credentials in two ways:
1. credentialsSecret: name (Kubernetes Secret in same namespace)
2. vaultSecretPath: path (Vault KV secret path - uses generateSecretPath pattern)

*/}}

{{- define "vault.mongoDBEngine" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}
{{- $vaultServer := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.selector) "vault" $root.Values.chapter.name ) | fromJson) "results" }}
{{- $mongoServers := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.mongoSelector) "mongodb" $root.Values.chapter.name ) | fromJson) "results" }}
{{- range $vaultConf := $vaultServer }}
{{- range $mongoConf := $mongoServers }}
{{- $databaseMount := default (printf "database-%s-%s" $root.Values.spellbook.name $root.Values.chapter.name) (default $glyphDefinition.databaseMount $mongoConf.databaseMount) }}
---
apiVersion: redhatcop.redhat.io/v1alpha1
kind: DatabaseSecretEngineConfig
metadata:
  name: {{ $mongoConf.name }}
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
  {{- include "vault.connect" (list $root $vaultConf "" $glyphDefinition.serviceAccount) | nindent 2 }}
  pluginName: mongodb-database-plugin
  allowedRoles:
    - read-write
    - read-only
  connectionURL: mongodb://{{`{{username}}`}}:{{`{{password}}`}}@{{ $mongoConf.host }}:{{ default "27017" $mongoConf.port }}/{{ default "admin" $mongoConf.database }}
  rootCredentials:
    {{- if $mongoConf.vaultSecretPath }}
    vaultSecret:
      path: {{ include "generateSecretPath" (list $root (dict "name" $mongoConf.name "path" $mongoConf.vaultSecretPath) $vaultConf "") }}
    {{- else }}
    secret:
      name: {{ required "mongodb credentialsSecret or vaultSecretPath is required" $mongoConf.credentialsSecret }}
    {{- end }}
    passwordKey: password
    usernameKey: username
  path: {{ $databaseMount }}
  rootPasswordRotation:
    enable: true
---
apiVersion: redhatcop.redhat.io/v1alpha1
kind: DatabaseSecretEngineRole
metadata:
  name: {{ $mongoConf.name }}-read-write
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
  {{- include "vault.connect" (list $root $vaultConf "" $glyphDefinition.serviceAccount) | nindent 2 }}
  path: {{ $databaseMount }}
  dBName: {{ default "admin" $mongoConf.database }}
  creationStatements:
    - '{ "db": "admin", "roles": [{ "role": "readWrite" }, {"role": "read", "db": "{{ default "admin" $mongoConf.database }}"}] }'
---
apiVersion: redhatcop.redhat.io/v1alpha1
kind: DatabaseSecretEngineRole
metadata:
  name: {{ $mongoConf.name }}-read-only
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
  {{- include "vault.connect" (list $root $vaultConf "" $glyphDefinition.serviceAccount) | nindent 2 }}
  path: {{ $databaseMount }}
  dBName: {{ default "admin" $mongoConf.database }}
  creationStatements:
    - '{ "db": "admin", "roles": [{"role": "read", "db": "{{ default "admin" $mongoConf.database }}"}] }'
{{- end }}
{{- end }}
{{- end }}
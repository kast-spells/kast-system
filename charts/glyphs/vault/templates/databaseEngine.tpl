{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

vault.postgresqlDBEngine creates PostgreSQL DatabaseSecretEngineConfig and roles for HashiCorp Vault.
Follows standard glyph parameter pattern: (list $root $glyphDefinition).

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: Database engine configuration object (index . 1)

Example glyph definition:
  vault:
    - type: postgresqlDBEngine
      name: postgres
      postgresSelector:
        app: my-app

Lexicon postgres entry can specify credentials in two ways:
1. credentialsSecret: name (Kubernetes Secret in same namespace)
2. vaultSecretPath: path (Vault KV secret path - uses generateSecretPath pattern)

*/}}

{{- define "vault.postgresqlDBEngine" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}
{{- $vaultServer := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.selector) "vault" $root.Values.chapter.name ) | fromJson) "results" }}
{{- $postgresServers := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.postgresSelector) "postgres" $root.Values.chapter.name ) | fromJson) "results" }}
{{- range $vaultConf := $vaultServer }}
{{- range $pgConf := $postgresServers }}
{{- $databaseMount := default (printf "database-%s-%s" $root.Values.spellbook.name $root.Values.chapter.name) (default $glyphDefinition.databaseMount $pgConf.databaseMount) }}
---
apiVersion: redhatcop.redhat.io/v1alpha1
kind: DatabaseSecretEngineConfig
metadata:
  name: {{ $pgConf.name }}
spec:
  {{- include "vault.connect" (list $root $vaultConf "" $glyphDefinition.serviceAccount) | nindent 2 }}
  pluginName: postgresql-database-plugin
  allowedRoles:
    - read-write
    - read-only
  connectionURL: postgresql://{{`{{username}}`}}:{{`{{password}}`}}@{{ $pgConf.host }}:{{ default "5432" $pgConf.port }}/{{ default "*" $pgConf.database }}
  rootCredentials:
    {{- if $pgConf.vaultSecretPath }}
    vaultSecret:
      path: {{ include "generateSecretPath" (list $root (dict "name" $pgConf.name "path" $pgConf.vaultSecretPath) $vaultConf "") }}
    {{- else }}
    secret:
      name: {{ required "postgres credentialsSecret or vaultSecretPath is required" $pgConf.credentialsSecret }}
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
  name: {{ $pgConf.name }}-read-write
spec:
  {{- include "vault.connect" (list $root $vaultConf "" $glyphDefinition.serviceAccount) | nindent 2 }}
  path: {{ $databaseMount }}
  dBName: {{ default "*" $pgConf.database }}
  creationStatements:
    - CREATE ROLE "{{`{{name}}`}}" WITH LOGIN PASSWORD '{{`{{password}}`}}' VALID UNTIL '{{`{{expiration}}`}}'; GRANT ALL ON ALL TABLES IN SCHEMA public TO "{{`{{name}}`}}";
---
apiVersion: redhatcop.redhat.io/v1alpha1
kind: DatabaseSecretEngineRole
metadata:
  name: {{ $pgConf.name }}-read-only
spec:
  {{- include "vault.connect" (list $root $vaultConf "" $glyphDefinition.serviceAccount) | nindent 2 }}
  path: {{ $databaseMount }}
  dBName: {{ default "*" $pgConf.database }}
  creationStatements:
    - CREATE ROLE "{{`{{name}}`}}" WITH LOGIN PASSWORD '{{`{{password}}`}}' VALID UNTIL '{{`{{expiration}}`}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO "{{`{{name}}`}}";
{{- end }}
{{- end }}
{{- end }}
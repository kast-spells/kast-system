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

*/}}

{{- define "vault.postgresqlDBEngine" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}
{{- $vaultServer := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.selector) "vault" $root.Values.chapter.name ) | fromJson) "results" }}
{{- $postgresServers := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.postgresSelector) "postgres" $root.Values.chapter.name ) | fromJson) "results" }}
{{- range $vaultConf := $vaultServer }}
{{- range $pgConf := $postgresServers }}
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
  rootCredentialsFromSecret:
    name: {{ $pgConf.credentialsSecret }}
  path: {{ $root.Values.spellbook.name }}/{{ $root.Values.chapter.name }}/{{ $pgConf.name }}/
  rootPasswordRotation:
    enable: true
---
apiVersion: redhatcop.redhat.io/v1alpha1
kind: DatabaseSecretEngineRole
metadata:
  name: {{ $pgConf.name }}-read-write
spec:
  {{- include "vault.connect" (list $root $vaultConf "" $glyphDefinition.serviceAccount) | nindent 2 }}
  path: {{ $root.Values.spellbook.name }}/{{ $root.Values.chapter.name }}/{{ $pgConf.name }}/
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
  path: {{ $root.Values.spellbook.name }}/{{ $root.Values.chapter.name }}/{{ $pgConf.name }}/
  dBName: {{ default "*" $pgConf.database }}
  creationStatements:
    - CREATE ROLE "{{`{{name}}`}}" WITH LOGIN PASSWORD '{{`{{password}}`}}' VALID UNTIL '{{`{{expiration}}`}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO "{{`{{name}}`}}";
{{- end }}
{{- end }}
{{- end }}
{{/*runik - Kubernetes arcane spelling technology
Copyright (C) 2025 namenmalkav@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

PostgreSQL dataStore helpers for microspell
*/}}

{{/*
Detect if psql is managed or external based on selector
Returns: "true" or "false"
*/}}
{{- define "microspell.psql.isExternal" -}}
  {{- if .Values.dataStore.psql.selector -}}
    {{- if gt (len .Values.dataStore.psql.selector) 0 -}}
      true
    {{- else -}}
      false
    {{- end -}}
  {{- else -}}
    false
  {{- end -}}
{{- end -}}

{{/*
Get cluster name
For managed: uses clusterName or default
For external: searches via runicIndexer
Returns: cluster name string
*/}}
{{- define "microspell.psql.clusterName" -}}
  {{- if eq (include "microspell.psql.isExternal" .) "true" -}}
    {{/* External: get from runicIndexer */}}
    {{- $pgClusters := get (include "runicIndexer.runicIndexer"
         (list .Values.lexicon
               .Values.dataStore.psql.selector
               "postgres"
               .Values.chapter.name) | fromJson) "results" }}
    {{- range $pgClusters }}
      {{- .name -}}
    {{- end }}
  {{- else -}}
    {{/* Managed: use clusterName or default */}}
    {{- default (printf "%s-pg" (include "common.name" .)) .Values.dataStore.psql.clusterName }}
  {{- end -}}
{{- end -}}

{{/*
Get database name
Returns: database name string
*/}}
{{- define "microspell.psql.database" -}}
  {{- default (include "common.name" .) .Values.dataStore.psql.database }}
{{- end -}}

{{/*
Get username
Returns: username string
*/}}
{{- define "microspell.psql.username" -}}
  {{- default (include "common.name" .) .Values.dataStore.psql.username }}
{{- end -}}

{{/*
Get host for connection
Supports pattern replacement: {clusterName}
Returns: host string
*/}}
{{- define "microspell.psql.host" -}}
  {{- $pattern := default "{clusterName}-rw" .Values.dataStore.psql.connection.host }}
  {{- $clusterName := include "microspell.psql.clusterName" . }}
  {{- $pattern | replace "{clusterName}" $clusterName }}
{{- end -}}

{{/*
Get port
Returns: port string
*/}}
{{- define "microspell.psql.port" -}}
  {{- default "5432" .Values.dataStore.psql.connection.port | toString }}
{{- end -}}

{{/*
Get superuser secret name (managed only)
Returns: secret name string
*/}}
{{- define "microspell.psql.superuserSecretName" -}}
  {{- if .Values.dataStore.psql.credentials.superuser.name }}
    {{- .Values.dataStore.psql.credentials.superuser.name }}
  {{- else }}
    {{- printf "%s-pg-superuser" (include "common.name" .) }}
  {{- end }}
{{- end -}}

{{/*
Get app credentials secret name
Returns: secret name for K8s Secret (created by VaultSecret)
*/}}
{{- define "microspell.psql.appSecretName" -}}
  {{- printf "%s-db-creds" (include "common.name" .) }}
{{- end -}}

{{/*
Get dynamic credentials role
Returns: role name for DatabaseSecretEngineRole
Format: {cluster-name}-{role}
*/}}
{{- define "microspell.psql.dynamicRole" -}}
  {{- $role := default "read-write" .Values.dataStore.psql.credentials.dynamic.role }}
  {{- printf "%s" $role }}
{{- end -}}

{{/*
Get database mount path
Returns: Vault database mount path
*/}}
{{- define "microspell.psql.databaseMount" -}}
  {{- printf "database-%s-%s" .Values.spellbook.name .Values.chapter.name }}
{{- end -}}

{{/*
Build connection string based on format
Returns: connection string template with variables
*/}}
{{- define "microspell.psql.connectionString" -}}
  {{- $format := default "dsn" .Values.dataStore.psql.connection.format }}
  {{- $host := include "microspell.psql.host" . }}
  {{- $port := include "microspell.psql.port" . }}
  {{- $database := include "microspell.psql.database" . }}
  {{- $username := include "microspell.psql.username" . }}

  {{- if or (eq $format "dsn") (eq $format "url") }}
    {{- $template := default "postgresql://{username}:{password}@{host}:{port}/{database}" .Values.dataStore.psql.connection.dsnTemplate }}
    {{- $sslMode := default "disable" .Values.dataStore.psql.connection.sslMode }}
    {{- $result := $template | replace "{host}" $host | replace "{port}" $port | replace "{database}" $database | replace "{username}" $username }}
    {{- if ne $sslMode "disable" }}
      {{- printf "%s?sslmode=%s" $result $sslMode }}
    {{- else }}
      {{- $result }}
    {{- end }}
  {{- end }}
{{- end -}}

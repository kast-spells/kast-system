{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2025 laaledesiempre@disroot.org
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}

{{- define "postgresql.cluster" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}

---
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: {{ default (include "common.name" $root ) $glyphDefinition.name }}
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
  # Description XXX
  description: {{ default (print "PostgreSQL cluster for" (default (include "common.name" $root ) $glyphDefinition.name)) $glyphDefinition.description }} # NOTE check

  # Image XXX
  {{- with $glyphDefinition.image }}
  imageName: {{ include "summon.getImage" (list $root $glyphDefinition) }}
  {{- end}}

  # instances XXX
  instances: {{ default 1 $glyphDefinition.instances }}

  {{- with $glyphDefinition.startDelay }}
  # startDelay XXX
  startDelay: {{ . }} # default 3600
  {{- end}}

  # stopDelay  XXX
  {{- with $glyphDefinition.stopDelay }}
  stopDelay: {{ . }} # default 1800
  {{- end}}

  # primaryUpdateStrategy XXX
  {{- with $glyphDefinition.primaryUpdateStrategy }}
  primaryUpdateStrategy: {{ . }}
  {{- end}}

  # Roles XXX
  {{- with $glyphDefinition.roles}}
  managed:
     roles:
       {{- toYaml . | nindent 6 }}
  {{- end}}

  # superuser XXX
  enableSuperuserAccess: {{ default true ($glyphDefinition.superuser).enabled }}
  {{- if $glyphDefinition.superuserSecret }}
  superuserSecret:
    name: {{ $glyphDefinition.superuserSecret }}
  {{- end }}

  # Bootstrap XXX
{{/*# example*/}}
{{- if or $glyphDefinition.dbName $glyphDefinition.userName $glyphDefinition.secret $glyphDefinition.postInitSQL $glyphDefinition.postInitApp $glyphDefinition.postInitTemplate $glyphDefinition.postInitPostgres }}
  bootstrap:
    initdb:
      database: {{ default (include "common.name" $root ) $glyphDefinition.dbName }}
      owner: {{ default (include "common.name" $root ) $glyphDefinition.userName }}

      # Add vault generator function #TODO
      {{- with $glyphDefinition.secret }} #FIXME
      secret:
        name: {{ . }}
      {{- end }}

      {{- with $glyphDefinition.postInitSQL }} #SQL executed outside transaction (for CREATE DATABASE)

      {{- if eq .type "cm" }}
      {{- $cmName := default (print "postgres-postinit-sql-" $glyphDefinition.name) .name }}

      # XXX postInitSQLRefs (executed outside transaction)
      postInitSQLRefs:
        configMapRefs:
          - name: {{ $cmName }}
            key: {{ $cmName }}

      {{- end }} #if for cm or secret

      {{- end }} #end for postInitSQL

      {{- with $glyphDefinition.postInitApp }} #leer la funcion de configmap en summon

      {{- if eq .type "cm" }}
      {{- $cmName := default (print "postgres-postinit-app-" $glyphDefinition.name) .name }}

      # XXX postInitApplicationSQLRefs
      postInitApplicationSQLRefs:
        configMapRefs:
          - name: {{ $cmName }}
            key: {{ $cmName }}

    #  {{- else}} # As secret
    #    secretRefs: # secret true mean uses secret directly, for prod #TODO
    #      - name: hildy-initdb #name
    #        key: configmap.sql #key

      {{- end }} #if for cm or secret

      {{- end }} #end for post init
{{- end}}

  # storage XXX
  storage:
    {{- if $glyphDefinition.storage }}
    {{- with $glyphDefinition.storage.storageClass }}
    storageClass: {{ . }}
    {{- end}}
    size: {{ default "1Gi" $glyphDefinition.storage.size }}
    {{- else }}
    size: 1Gi
    {{- end }}

  # resources XXX
  {{- with $glyphDefinition.resources }}
  {{- toYaml . | nindent 2 }}
  {{- end }}

  # affinity XXX
  {{- with $glyphDefinition.affinity }}
  {{- toYaml . | nindent 2 }}
  {{- end }}

  # postgresql XXX
  {{- with $glyphDefinition.postgresql }} #TODO ver como se gestionan los defaults con herencia #prod
  {{- toYaml . | nindent 2 }}
  {{- end }}

{{/* Create ConfigMaps for postInitSQL if needed */}}
{{- with $glyphDefinition.postInitSQL }}
{{- if and (eq .type "cm") (eq .create true) }}
{{- $cmName := default (print "postgres-postinit-sql-" $glyphDefinition.name) .name }}
{{- $defaultValues := dict "name" $cmName "definition" (dict "content" .content "contentType" "file") }}
{{- include "summon.configMap" ( list $root $defaultValues ) }}
{{- end}}
{{- end}}

{{/* Create ConfigMaps for postInitApp if needed */}}
{{- with $glyphDefinition.postInitApp }}
{{- if and (eq .type "cm") (eq .create true) }}
{{- $cmName := default (print "postgres-postinit-app-" $glyphDefinition.name) .name }}
{{- $defaultValues := dict "name" $cmName "definition" (dict "content" .content "contentType" "file") }}
{{- include "summon.configMap" ( list $root $defaultValues ) }}
{{- end}}
{{- end}}

{{- end}}

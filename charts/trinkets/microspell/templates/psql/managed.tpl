{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2025 namenmalkav@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

MANAGED PostgreSQL cluster
Creates new CNPG cluster with Vault DB Engine integration
*/}}

{{- define "microspell.psql.managed" -}}
{{- $clusterName := include "microspell.psql.clusterName" . }}
{{- $database := include "microspell.psql.database" . }}
{{- $username := include "microspell.psql.username" . }}
{{- $superuserSecretName := include "microspell.psql.superuserSecretName" . }}
{{- $appSecretName := include "microspell.psql.appSecretName" . }}
{{- $databaseMount := include "microspell.psql.databaseMount" . }}
{{- $dynamicRole := include "microspell.psql.dynamicRole" . }}

{{/*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/}}
{{/* Step 1: Superuser Secret (for bootstrap + DB Engine) */}}
{{/*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/}}
glyphs:
  vault:
    # Superuser credentials (static, for bootstrap)
    {{ $superuserSecretName }}:
      type: secret
      secretType: {{ default "kubernetes.io/basic-auth" .Values.dataStore.psql.credentials.superuser.secretType }}
      {{- with .Values.dataStore.psql.credentials.superuser.vaultSelector }}
      selector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      staticData:
        username: postgres
      random: true
      {{- if .Values.serviceAccount.name }}
      serviceAccount: {{ .Values.serviceAccount.name }}
      {{- end }}

{{/*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/}}
{{/* Step 2: CNPG Cluster */}}
{{/*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/}}
  postgre:
    {{ $clusterName }}:
      type: cluster
      name: {{ $clusterName }}
      dbName: {{ $database }}
      userName: {{ $username }}
      secret: {{ $superuserSecretName }}
      {{- if .Values.dataStore.psql.credentials.superuser.enabled }}
      superuserSecret: {{ $superuserSecretName }}
      {{- end }}

      instances: {{ default 1 .Values.dataStore.psql.cluster.instances }}

      {{- with .Values.dataStore.psql.cluster.image }}
      image:
        {{- toYaml . | nindent 8 }}
      {{- end }}

      storage:
        {{- if .Values.dataStore.psql.cluster.storage }}
        {{- toYaml .Values.dataStore.psql.cluster.storage | nindent 8 }}
        {{- else }}
        size: 10Gi
        {{- end }}

      {{- with .Values.dataStore.psql.cluster.resources }}
      resources:
        {{- toYaml . | nindent 8 }}
      {{- end }}

      {{- with .Values.dataStore.psql.cluster.startDelay }}
      startDelay: {{ . }}
      {{- end }}

      {{- with .Values.dataStore.psql.cluster.stopDelay }}
      stopDelay: {{ . }}
      {{- end }}

      {{- with .Values.dataStore.psql.cluster.primaryUpdateStrategy }}
      primaryUpdateStrategy: {{ . }}
      {{- end }}

      {{- with .Values.dataStore.psql.cluster.roles }}
      roles:
        {{- toYaml . | nindent 8 }}
      {{- end }}

      {{- with .Values.dataStore.psql.cluster.postgresql }}
      postgresql:
        {{- toYaml . | nindent 8 }}
      {{- end }}

      {{- with .Values.dataStore.psql.cluster.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}

      {{- if .Values.dataStore.psql.initDb.enabled }}
      # Post-bootstrap initialization (uses superuser)
      postInitApp:
        type: cm
        {{- if .Values.dataStore.psql.initDb.configMap.name }}
        name: {{ .Values.dataStore.psql.initDb.configMap.name }}
        key: {{ default "init.sql" .Values.dataStore.psql.initDb.configMap.key }}
        {{- else }}
        name: {{ printf "%s-initdb" $clusterName }}
        key: init.sql
        create: true
        content: |
          {{- .Values.dataStore.psql.initDb.sql | nindent 10 }}
        {{- end }}
      {{- end }}

{{/*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/}}
{{/* Step 3: Vault Database Secret Engine Mount */}}
{{/*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/}}
  vault:
    # Database secrets engine mount (shared for book/chapter)
    db-engine-mount:
      type: secretEngineMount
      mountType: database
      description: "Database secrets engine for {{ .Values.spellbook.name }}/{{ .Values.chapter.name }}"
      {{- if .Values.serviceAccount.name }}
      serviceAccount: {{ .Values.serviceAccount.name }}
      {{- end }}

{{/*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/}}
{{/* Step 4: DatabaseSecretEngineConfig + Roles */}}
{{/*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/}}
    # Configure DB Engine for this cluster
    db-engine-config:
      type: postgresqlDBEngine
      postgresSelector:
        name: {{ $clusterName }}
      {{- if .Values.serviceAccount.name }}
      serviceAccount: {{ .Values.serviceAccount.name }}
      {{- end }}

{{/*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/}}
{{/* Step 5: App Dynamic Credentials */}}
{{/*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/}}
    # Dynamic credentials for the app
    {{ $appSecretName }}:
      type: secret
      generationType: "database"
      databaseEngine: {{ $clusterName | quote }}
      databaseRole: {{ $dynamicRole | quote }}
      databaseMount: {{ $databaseMount | quote }}
      format: env
      keys:
        - username
        - password
      {{- $ttl := .Values.dataStore.psql.credentials.dynamic.ttl }}
      {{- if $ttl }}
      refreshPeriod: {{ $ttl }}
      {{- else }}
      refreshPeriod: 30m
      {{- end }}
      {{- if .Values.serviceAccount.name }}
      serviceAccount: {{ .Values.serviceAccount.name }}
      {{- end }}

{{- end -}}

{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2025 namenmalkav@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

EXTERNAL PostgreSQL cluster
Uses existing cluster via runicIndexer and Vault DB Engine
*/}}

{{- define "microspell.psql.external" -}}
{{- $appSecretName := include "microspell.psql.appSecretName" . }}
{{- $database := include "microspell.psql.database" . }}
{{- $username := include "microspell.psql.username" . }}
{{- $dynamicRole := include "microspell.psql.dynamicRole" . }}

{{/* Find postgres cluster via runicIndexer */}}
{{- $pgClusters := get (include "runicIndexer.runicIndexer"
     (list .Values.lexicon
           .Values.dataStore.psql.selector
           "postgres"
           .Values.chapter.name) | fromJson) "results" }}

{{- range $pgCluster := $pgClusters }}
{{- $databaseMount := default (printf "database-%s-%s" $.Values.spellbook.name $.Values.chapter.name) $pgCluster.databaseMount }}

{{/*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/}}
{{/* Step 1: App Dynamic Credentials */}}
{{/*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/}}
glyphs:
  vault:
    # Dynamic credentials from existing DB Engine
    {{ $appSecretName }}:
      type: secret
      generationType: "database"
      databaseEngine: {{ $pgCluster.name | quote }}
      databaseRole: {{ $dynamicRole | quote }}
      databaseMount: {{ $databaseMount | quote }}
      format: env
      keys:
        - username
        - password
      {{- $ttl := $.Values.dataStore.psql.credentials.dynamic.ttl }}
      {{- if $ttl }}
      refreshPeriod: {{ $ttl }}
      {{- else }}
      refreshPeriod: 30m
      {{- end }}
      {{- if $.Values.serviceAccount.name }}
      serviceAccount: {{ $.Values.serviceAccount.name }}
      {{- end }}

{{/*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/}}
{{/* Step 2: Schema Initialization Job (optional) */}}
{{/*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/}}
{{- if $.Values.dataStore.psql.initDb.enabled }}
---
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "common.name" $ }}-db-init
  annotations:
    argocd.argoproj.io/sync-wave: "5"  # Run after cluster is ready
    argocd.argoproj.io/hook: PostSync
    argocd.argoproj.io/hook-delete-policy: BeforeHookCreation
spec:
  backoffLimit: {{ default 3 $.Values.dataStore.psql.initDb.job.backoffLimit }}
  template:
    metadata:
      name: {{ include "common.name" $ }}-db-init
    spec:
      restartPolicy: {{ default "OnFailure" $.Values.dataStore.psql.initDb.job.restartPolicy }}
      {{- if $.Values.serviceAccount.enabled }}
      serviceAccountName: {{ default (include "common.name" $) $.Values.serviceAccount.name }}
      {{- end }}
      containers:
      - name: db-init
        image: {{ default "postgres" $.Values.dataStore.psql.initDb.job.image.repository }}:{{ default "16-alpine" $.Values.dataStore.psql.initDb.job.image.tag }}
        command:
        - sh
        - -c
        - |
          set -e
          echo "Waiting for database to be ready..."
          until pg_isready -h {{ $pgCluster.host }} -p {{ default "5432" $pgCluster.port }} -U ${PGUSER}; do
            echo "Waiting..."
            sleep 2
          done

          echo "Running schema initialization..."
          {{- if $.Values.dataStore.psql.initDb.configMap.name }}
          psql -h {{ $pgCluster.host }} -p {{ default "5432" $pgCluster.port }} -U ${PGUSER} -d {{ $database }} -f /sql/{{ default "init.sql" $.Values.dataStore.psql.initDb.configMap.key }}
          {{- else }}
          cat <<'EOF' | psql -h {{ $pgCluster.host }} -p {{ default "5432" $pgCluster.port }} -U ${PGUSER} -d {{ $database }}
          {{- $.Values.dataStore.psql.initDb.sql | nindent 10 }}
          EOF
          {{- end }}

          echo "Schema initialization completed successfully"
        env:
        - name: PGUSER
          valueFrom:
            secretKeyRef:
              name: {{ $appSecretName }}
              key: USERNAME
        - name: PGPASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ $appSecretName }}
              key: PASSWORD
        {{- if $.Values.dataStore.psql.initDb.configMap.name }}
        volumeMounts:
        - name: sql
          mountPath: /sql
        {{- end }}
      {{- if $.Values.dataStore.psql.initDb.configMap.name }}
      volumes:
      - name: sql
        configMap:
          name: {{ $.Values.dataStore.psql.initDb.configMap.name }}
      {{- end }}
{{- end }}

{{- end }}
{{- end -}}

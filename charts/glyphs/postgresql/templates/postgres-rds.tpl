{{/*runik - Kubernetes arcane spelling technology
Copyright (C) 2025 kazapeke@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}

{{- define "postgresql.rds" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}

{{- $serviceName := default (print (include "common.name" $root) "-svc") (($glyphDefinition.service).name) }}
{{- $endpoint := $glyphDefinition.endpoint }}
{{- $port := default 5432 $glyphDefinition.port }}
{{- $database := default "postgres" $glyphDefinition.database }}

---
# ExternalName Service pointing to RDS endpoint
apiVersion: v1
kind: Service
metadata:
  name: {{ $serviceName }}
  labels:
    {{- include "common.all.labels" $root | nindent 4 }}
    app.kubernetes.io/component: database
    database.type: rds
    database.engine: postgresql
    {{- with $glyphDefinition.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $glyphDefinition.annotations }}
  annotations:
    {{- include "common.annotations" $root | nindent 4 }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  type: ExternalName
  externalName: {{ $endpoint }}
  {{- if or (($glyphDefinition.service).ports) (($glyphDefinition.service).enabled) }}
  ports:
    {{- if (($glyphDefinition.service).ports) }}
    {{- range (($glyphDefinition.service).ports) }}
    - name: {{ default "postgresql" .name }}
      port: {{ default $port .port }}
      {{- with .targetPort }}
      targetPort: {{ . }}
      {{- end }}
      protocol: {{ default "TCP" .protocol }}
    {{- end }}
    {{- else }}
    - name: postgresql
      port: {{ $port }}
      protocol: TCP
    {{- end }}
  {{- end }}

---
# ConfigMap with RDS connection information
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ default (include "common.name" $root) $glyphDefinition.name }}-connection
  labels:
    {{- include "common.all.labels" $root | nindent 4 }}
    app.kubernetes.io/component: database-config
    database.type: rds
    {{- with $glyphDefinition.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $glyphDefinition.annotations }}
  annotations:
    {{- include "common.annotations" $root | nindent 4 }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
data:
  PGHOST: {{ $endpoint | quote }}
  PGPORT: {{ $port | quote }}
  PGDATABASE: {{ $database | quote }}
  DB_HOST: {{ $endpoint | quote }}
  DB_PORT: {{ $port | quote }}
  DB_NAME: {{ $database | quote }}
  DB_DATABASE: {{ $database | quote }}
  SERVICE_NAME: {{ $serviceName | quote }}
  {{- if $glyphDefinition.ssl }}
  {{- if (($glyphDefinition.ssl).enabled) }}
  PGSSLMODE: {{ default "require" (($glyphDefinition.ssl).mode) | quote }}
  DB_SSL_MODE: {{ default "require" (($glyphDefinition.ssl).mode) | quote }}
  {{- end }}
  {{- end }}
  {{- if $glyphDefinition.connectionPool }}
  DB_POOL_MAX: {{ default "100" (($glyphDefinition.connectionPool).maxConnections) | quote }}
  DB_POOL_MIN: {{ default "10" (($glyphDefinition.connectionPool).minConnections) | quote }}
  DB_POOL_IDLE_TIMEOUT: {{ default "300" (($glyphDefinition.connectionPool).idleTimeout) | quote }}
  {{- end }}

{{/* Optional: Create Secret with direct credentials (not recommended for production) */}}
{{- if and $glyphDefinition.credentials (not $glyphDefinition.credentialsSecret) }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ default (include "common.name" $root) $glyphDefinition.name }}-credentials
  labels:
    {{- include "common.all.labels" $root | nindent 4 }}
    app.kubernetes.io/component: database-credentials
    database.type: rds
    {{- with $glyphDefinition.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $glyphDefinition.annotations }}
  annotations:
    {{- include "common.annotations" $root | nindent 4 }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
type: Opaque
stringData:
  {{- with (($glyphDefinition.credentials).username) }}
  PGUSER: {{ . | quote }}
  DB_USER: {{ . | quote }}
  username: {{ . | quote }}
  {{- end }}
  {{- with (($glyphDefinition.credentials).password) }}
  PGPASSWORD: {{ . | quote }}
  DB_PASSWORD: {{ . | quote }}
  password: {{ . | quote }}
  {{- end }}
{{- end }}

{{/* Reference ConfigMap for connection string construction */}}
{{- if $glyphDefinition.credentialsSecret }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ default (include "common.name" $root) $glyphDefinition.name }}-connection-template
  labels:
    {{- include "common.all.labels" $root | nindent 4 }}
    app.kubernetes.io/component: database-config
    database.type: rds
    {{- with $glyphDefinition.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $glyphDefinition.annotations }}
  annotations:
    {{- include "common.annotations" $root | nindent 4 }}
    description: "Connection string template - combine with credentials secret"
    {{- toYaml . | nindent 4 }}
  {{- end }}
data:
  connection-info.txt: |
    # PostgreSQL RDS Connection Information
    # =====================================

    Database Type: AWS RDS PostgreSQL
    Endpoint: {{ $endpoint }}
    Port: {{ $port }}
    Database: {{ $database }}
    Service Name: {{ $serviceName }}

    # Credentials Secret
    Secret Name: {{ (($glyphDefinition.credentialsSecret).name) }}
    {{- if (($glyphDefinition.credentialsSecret).usernameKey) }}
    Username Key: {{ (($glyphDefinition.credentialsSecret).usernameKey) }}
    {{- end }}
    {{- if (($glyphDefinition.credentialsSecret).passwordKey) }}
    Password Key: {{ (($glyphDefinition.credentialsSecret).passwordKey) }}
    {{- end }}

    # Connection String Template
    {{- if $glyphDefinition.ssl }}
    {{- if (($glyphDefinition.ssl).enabled) }}
    postgresql://${USERNAME}:${PASSWORD}@{{ $endpoint }}:{{ $port }}/{{ $database }}?sslmode={{ default "require" (($glyphDefinition.ssl).mode) }}
    {{- else }}
    postgresql://${USERNAME}:${PASSWORD}@{{ $endpoint }}:{{ $port }}/{{ $database }}
    {{- end }}
    {{- else }}
    postgresql://${USERNAME}:${PASSWORD}@{{ $endpoint }}:{{ $port }}/{{ $database }}
    {{- end }}

    # Environment Variables to Mount
    # From ConfigMap: {{ default (include "common.name" $root) $glyphDefinition.name }}-connection
    #   - PGHOST, PGPORT, PGDATABASE, DB_HOST, DB_PORT, DB_NAME
    # From Secret: {{ (($glyphDefinition.credentialsSecret).name) }}
    #   - PGUSER, PGPASSWORD, DB_USER, DB_PASSWORD
{{- end }}

{{/* Optional: SSL/TLS CA Certificate Secret reference */}}
{{- if and $glyphDefinition.ssl (($glyphDefinition.ssl).enabled) (($glyphDefinition.ssl).caCertSecret) }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ default (include "common.name" $root) $glyphDefinition.name }}-ssl-config
  labels:
    {{- include "common.all.labels" $root | nindent 4 }}
    app.kubernetes.io/component: database-ssl-config
    database.type: rds
    {{- with $glyphDefinition.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
data:
  ssl-info.txt: |
    # SSL/TLS Configuration
    SSL Mode: {{ default "require" (($glyphDefinition.ssl).mode) }}
    CA Certificate Secret: {{ ((($glyphDefinition.ssl).caCertSecret).name) }}
    CA Certificate Key: {{ ((($glyphDefinition.ssl).caCertSecret).key) }}

    # Mount the CA certificate from secret to: /etc/ssl/certs/rds-ca.crt
    # Set environment variable: PGSSLROOTCERT=/etc/ssl/certs/rds-ca.crt
{{- end }}

{{- end}}

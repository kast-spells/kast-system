{{/*runik - Kubernetes arcane spelling technology
Copyright (C) 2026  kazapeke@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}

{{- define "postgresql.rds" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}

---
apiVersion: rds.services.k8s.aws/v1alpha1
kind: DBInstance
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
  # Required fields
  dbInstanceClass: {{ required "dbInstanceClass is required" $glyphDefinition.dbInstanceClass }}
  dbInstanceIdentifier: {{ required "dbInstanceIdentifier is required" $glyphDefinition.dbInstanceIdentifier }}
  engine: {{ required "engine is required" $glyphDefinition.engine }}

  # Engine version
  {{- with $glyphDefinition.engineVersion }}
  engineVersion: {{ . | quote }}
  {{- end }}

  # Master credentials
  {{- with $glyphDefinition.masterUsername }}
  masterUsername: {{ . }}
  {{- end }}

  {{- with $glyphDefinition.masterUserPassword }}
  masterUserPassword:
    name: {{ .name }}
    key: {{ default "password" .key }}
  {{- end }}

  # Database name
  {{- with $glyphDefinition.dbName }}
  dbName: {{ . }}
  {{- end }}

  # Storage
  allocatedStorage: {{ default 20 $glyphDefinition.allocatedStorage }}

  {{- with $glyphDefinition.storage }}
  {{- with .storageType }}
  storageType: {{ . }}
  {{- end }}
  {{- with .iops }}
  iops: {{ . }}
  {{- end }}
  {{- with .storageThroughput }}
  storageThroughput: {{ . }}
  {{- end }}
  {{- with .storageEncrypted }}
  storageEncrypted: {{ . }}
  {{- end }}
  {{- with .kmsKeyID }}
  kmsKeyID: {{ . }}
  {{- end }}
  {{- end }}

  # Networking
  {{- with $glyphDefinition.networking }}
  {{- with .availabilityZone }}
  availabilityZone: {{ . }}
  {{- end }}
  {{- with .dbSubnetGroupName }}
  dbSubnetGroupName: {{ . }}
  {{- end }}
  {{- with .vpcSecurityGroupIDs }}
  vpcSecurityGroupIDs:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .publiclyAccessible }}
  publiclyAccessible: {{ . }}
  {{- end }}
  {{- with .multiAZ }}
  multiAZ: {{ . }}
  {{- end }}
  {{- with .port }}
  port: {{ . }}
  {{- end }}
  {{- end }}

  # Backup configuration
  {{- with $glyphDefinition.backup }}
  {{- with .backupRetentionPeriod }}
  backupRetentionPeriod: {{ . }}
  {{- end }}
  {{- with .preferredBackupWindow }}
  preferredBackupWindow: {{ . }}
  {{- end }}
  {{- with .preferredMaintenanceWindow }}
  preferredMaintenanceWindow: {{ . }}
  {{- end }}
  {{- with .copyTagsToSnapshot }}
  copyTagsToSnapshot: {{ . }}
  {{- end }}
  {{- end }}

  # High availability and updates
  {{- with $glyphDefinition.autoMinorVersionUpgrade }}
  autoMinorVersionUpgrade: {{ . }}
  {{- end }}

  {{- with $glyphDefinition.deletionProtection }}
  deletionProtection: {{ . }}
  {{- end }}

  # Monitoring
  {{- with $glyphDefinition.monitoring }}
  {{- with .monitoringInterval }}
  monitoringInterval: {{ . }}
  {{- end }}
  {{- with .monitoringRoleARN }}
  monitoringRoleARN: {{ . }}
  {{- end }}
  {{- with .enablePerformanceInsights }}
  enablePerformanceInsights: {{ . }}
  {{- end }}
  {{- with .performanceInsightsRetentionPeriod }}
  performanceInsightsRetentionPeriod: {{ . }}
  {{- end }}
  {{- with .performanceInsightsKMSKeyID }}
  performanceInsightsKMSKeyID: {{ . }}
  {{- end }}
  {{- end }}

  # Security and authentication
  {{- with $glyphDefinition.enableIAMDatabaseAuthentication }}
  enableIAMDatabaseAuthentication: {{ . }}
  {{- end }}

  {{- with $glyphDefinition.caCertificateIdentifier }}
  caCertificateIdentifier: {{ . }}
  {{- end }}

  # CloudWatch logs export
  {{- with $glyphDefinition.enableCloudwatchLogsExports }}
  enableCloudwatchLogsExports:
    {{- toYaml . | nindent 4 }}
  {{- end }}

  # Parameter and option groups
  {{- with $glyphDefinition.parameterGroupName }}
  dbParameterGroupName: {{ . }}
  {{- end }}

  {{- with $glyphDefinition.optionGroupName }}
  optionGroupName: {{ . }}
  {{- end }}

  # Tags
  {{- with $glyphDefinition.tags }}
  tags:
    {{- toYaml . | nindent 4 }}
  {{- end }}

{{- end }}

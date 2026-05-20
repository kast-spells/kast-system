{{/*runik - Kubernetes arcane spelling technology
Copyright (C) 2026 kazapeke@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "aws.dynamodb-table" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}
---
apiVersion: dynamodb.services.k8s.aws/v1alpha1
kind: Table
metadata:
  name: {{ default (include "common.name" $root) $glyphDefinition.name }}
  namespace: {{ default $root.Release.Namespace $glyphDefinition.namespace }}
  labels:
    {{- include "common.all.labels" $root | nindent 4 }}
    {{- with $glyphDefinition.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- if or $glyphDefinition.annotations $glyphDefinition.adoptionPolicy }}
  annotations:
    {{- if $glyphDefinition.adoptionPolicy }}
    services.k8s.aws/adoption-policy: {{ $glyphDefinition.adoptionPolicy }}
    {{- end }}
    {{- with $glyphDefinition.annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- end }}
spec:
  tableName: {{ default (include "common.name" $root) $glyphDefinition.tableName }}

  {{- /* Key Schema (required) */}}
  keySchema:
    {{- range $glyphDefinition.keySchema }}
    - attributeName: {{ .attributeName }}
      keyType: {{ .keyType }}
    {{- end }}

  {{- /* Attribute Definitions (required) */}}
  attributeDefinitions:
    {{- range $glyphDefinition.attributeDefinitions }}
    - attributeName: {{ .attributeName }}
      attributeType: {{ .attributeType | quote }}
    {{- end }}

  {{- /* Billing Mode - defaults to PAY_PER_REQUEST (on-demand) */}}
  billingMode: {{ default "PAY_PER_REQUEST" $glyphDefinition.billingMode }}

  {{- /* Provisioned Throughput (required when billingMode is PROVISIONED) */}}
  {{- with $glyphDefinition.provisionedThroughput }}
  provisionedThroughput:
    readCapacityUnits: {{ .readCapacityUnits }}
    writeCapacityUnits: {{ .writeCapacityUnits }}
  {{- end }}

  {{- /* Global Secondary Indexes */}}
  {{- with $glyphDefinition.globalSecondaryIndexes }}
  globalSecondaryIndexes:
    {{- range . }}
    - indexName: {{ .indexName }}
      keySchema:
        {{- range .keySchema }}
        - attributeName: {{ .attributeName }}
          keyType: {{ .keyType }}
        {{- end }}
      projection:
        projectionType: {{ default "ALL" .projection.projectionType }}
        {{- with .projection.nonKeyAttributes }}
        nonKeyAttributes:
          {{- toYaml . | nindent 10 }}
        {{- end }}
      {{- if .provisionedThroughput }}
      provisionedThroughput:
        readCapacityUnits: {{ .provisionedThroughput.readCapacityUnits }}
        writeCapacityUnits: {{ .provisionedThroughput.writeCapacityUnits }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* Local Secondary Indexes */}}
  {{- with $glyphDefinition.localSecondaryIndexes }}
  localSecondaryIndexes:
    {{- range . }}
    - indexName: {{ .indexName }}
      keySchema:
        {{- range .keySchema }}
        - attributeName: {{ .attributeName }}
          keyType: {{ .keyType }}
        {{- end }}
      projection:
        projectionType: {{ default "ALL" .projection.projectionType }}
        {{- with .projection.nonKeyAttributes }}
        nonKeyAttributes:
          {{- toYaml . | nindent 10 }}
        {{- end }}
    {{- end }}
  {{- end }}

  {{- /* DynamoDB Streams */}}
  {{- with $glyphDefinition.streamSpecification }}
  streamSpecification:
    streamEnabled: {{ default true .streamEnabled }}
    streamViewType: {{ default "NEW_AND_OLD_IMAGES" .streamViewType }}
  {{- end }}

  {{- /* Time to Live */}}
  {{- with $glyphDefinition.timeToLive }}
  timeToLive:
    attributeName: {{ .attributeName }}
    enabled: {{ default true .enabled }}
  {{- end }}

  {{- /* Server-Side Encryption */}}
  {{- with $glyphDefinition.sseSpecification }}
  sseSpecification:
    enabled: {{ default true .enabled }}
    {{- with .kmsMasterKeyID }}
    kmsMasterKeyID: {{ . }}
    {{- end }}
    {{- with .sseType }}
    sseType: {{ . }}
    {{- end }}
  {{- end }}

  {{- /* Point-in-Time Recovery */}}
  {{- with $glyphDefinition.continuousBackups }}
  continuousBackups:
    pointInTimeRecoveryEnabled: {{ default false .pointInTimeRecoveryEnabled }}
  {{- end }}

  {{- /* Deletion Protection */}}
  {{- if $glyphDefinition.deletionProtectionEnabled }}
  deletionProtectionEnabled: {{ $glyphDefinition.deletionProtectionEnabled }}
  {{- end }}

  {{- /* Table Class */}}
  {{- with $glyphDefinition.tableClass }}
  tableClass: {{ . }}
  {{- end }}

  {{- /* Contributor Insights */}}
  {{- with $glyphDefinition.contributorInsights }}
  contributorInsights: {{ . }}
  {{- end }}

  {{- /* Resource Policy */}}
  {{- with $glyphDefinition.resourcePolicy }}
  resourcePolicy: {{ . | quote }}
  {{- end }}

  {{- /* Tags */}}
  {{- if $glyphDefinition.tags }}
  tags:
    {{- range $glyphDefinition.tags }}
    - key: {{ .key }}
      value: {{ .value | quote }}
    {{- end }}
  {{- else }}
  tags:
    - key: Name
      value: {{ default (include "common.name" $root) $glyphDefinition.tableName | quote }}
    - key: ManagedBy
      value: "ack-dynamodb-controller"
  {{- end }}
{{- end }}

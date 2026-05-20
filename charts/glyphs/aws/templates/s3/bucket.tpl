{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2026 kazapeke@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "aws.s3-bucket" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}
---
apiVersion: s3.services.k8s.aws/v1alpha1
kind: Bucket
metadata:
  name: {{ $glyphDefinition.name }}
  namespace: {{ default "ack-system" $glyphDefinition.namespace }}
  labels:
    {{- include "common.all.labels" $root | nindent 4 }}
    {{- with $glyphDefinition.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $glyphDefinition.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  name: {{ $glyphDefinition.name }}

  {{- /* Public Access Block - defaults to blocking all public access */}}
  publicAccessBlock:
    {{- if $glyphDefinition.publicAccessBlock }}
    blockPublicACLs: {{ default true $glyphDefinition.publicAccessBlock.blockPublicACLs }}
    blockPublicPolicy: {{ default true $glyphDefinition.publicAccessBlock.blockPublicPolicy }}
    ignorePublicACLs: {{ default true $glyphDefinition.publicAccessBlock.ignorePublicACLs }}
    restrictPublicBuckets: {{ default true $glyphDefinition.publicAccessBlock.restrictPublicBuckets }}
    {{- else }}
    blockPublicACLs: true
    blockPublicPolicy: true
    ignorePublicACLs: true
    restrictPublicBuckets: true
    {{- end }}

  {{- /* Ownership Controls */}}
  {{- if $glyphDefinition.ownershipControls }}
  ownershipControls:
    rules:
      {{- range $glyphDefinition.ownershipControls.rules }}
      - objectOwnership: {{ .objectOwnership }}
      {{- end }}
  {{- else }}
  ownershipControls:
    rules:
      - objectOwnership: BucketOwnerEnforced
  {{- end }}

  {{- /* Encryption - defaults to AES256 */}}
  {{- if $glyphDefinition.encryption }}
  encryption:
    rules:
      {{- range $glyphDefinition.encryption.rules }}
      - applyServerSideEncryptionByDefault:
          sseAlgorithm: {{ default "AES256" .sseAlgorithm }}
          {{- if .kmsKeyID }}
          kmsMasterKeyID: {{ .kmsKeyID }}
          {{- end }}
        bucketKeyEnabled: {{ default true .bucketKeyEnabled }}
      {{- end }}
  {{- else }}
  encryption:
    rules:
      - applyServerSideEncryptionByDefault:
          sseAlgorithm: AES256
        bucketKeyEnabled: true
  {{- end }}

  {{- /* Versioning */}}
  {{- if $glyphDefinition.versioning }}
  versioning:
    status: {{ default "Suspended" $glyphDefinition.versioning.status }}
  {{- else }}
  versioning:
    status: Suspended
  {{- end }}

  {{- /* Lifecycle Configuration */}}
  {{- with $glyphDefinition.lifecycleConfiguration }}
  lifecycle:
    rules:
      {{- toYaml .rules | nindent 6 }}
  {{- end }}

  {{- /* CORS Configuration */}}
  {{- with $glyphDefinition.cors }}
  cors:
    corsRules:
      {{- toYaml .rules | nindent 6 }}
  {{- end }}

  {{- /* Logging */}}
  {{- with $glyphDefinition.logging }}
  logging:
    loggingEnabled:
      targetBucket: {{ .targetBucket }}
      {{- if .targetPrefix }}
      targetPrefix: {{ .targetPrefix }}
      {{- end }}
  {{- end }}

  {{- /* Tags */}}
  {{- if $glyphDefinition.tags }}
  tagging:
    tagSet:
      {{- range $glyphDefinition.tags }}
      - key: {{ .key }}
        value: {{ .value }}
      {{- end }}
  {{- else }}
  tagging:
    tagSet:
      - key: Name
        value: {{ $glyphDefinition.name }}
      - key: ManagedBy
        value: ack-s3-controller
  {{- end }}
{{- end }}

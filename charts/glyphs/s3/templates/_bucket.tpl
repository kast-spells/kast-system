{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

s3.bucket - Creates dual-namespace VaultSecrets for S3 bucket access

Creates:
1. VaultSecret in app namespace (for app consumption via secrets.contentType:env)
2. VaultSecret in provider namespace (for aggregation into S3 config)

Both secrets use the same vault path (/s3-identities/<identity>) with randomKeys enhancement
*/}}

{{- define "s3.bucket.impl" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 -}}
{{- $name := $glyphDefinition.name -}}

{{- /* Find S3 provider via runicIndexer (default: book fallback) */}}
{{- $selector := default (dict "default" "book") $glyphDefinition.selector }}
{{- $s3Providers := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon $selector "s3-provider" $root.Values.chapter.name) | fromJson) "results" }}

{{- if not $s3Providers }}
  {{- fail (printf "s3.bucket: No S3 provider found for selector %v. Ensure seaweedfs is deployed with s3-provider lexicon entry." $selector) }}
{{- end }}

{{- range $s3Provider := $s3Providers }}

{{- /* Generate identity name and defaults */}}
{{- $identityName := printf "%s-%s-%s" $root.Values.spellbook.name $root.Values.chapter.name $name }}
{{- $bucketName := default (printf "%s-%s-%s" $root.Values.spellbook.name $root.Values.chapter.name $name) $glyphDefinition.bucket }}
{{- $permissions := default (list "Admin") $glyphDefinition.permissions }}

{{- /* Bucket patterns: exact bucket by default, pattern:true adds -*, pattern:[list] uses custom patterns */}}
{{- $bucketPatterns := list }}
{{- if $glyphDefinition.pattern }}
  {{- if eq (kindOf $glyphDefinition.pattern) "bool" }}
    {{- /* pattern: true -> bucket-* */}}
    {{- $bucketPatterns = list (printf "%s-*" $bucketName) }}
  {{- else if eq (kindOf $glyphDefinition.pattern) "slice" }}
    {{- /* pattern: ["prefix-*", "*-suffix"] -> custom patterns */}}
    {{- $bucketPatterns = $glyphDefinition.pattern }}
  {{- end }}
{{- else }}
  {{- /* Default: exact bucket name */}}
  {{- $bucketPatterns = list $bucketName }}
{{- end }}

{{- /* Generate unique identity name for vault secret */}}
{{- $secretName := printf "s3-identities-%s-%s" $s3Provider.name $name }}

{{- /* 1. VaultSecret in APP NAMESPACE (for app consumption) */}}
{{- /* Only create if app namespace != provider namespace (avoid duplicate when same namespace) */}}
{{- if ne $root.Release.Namespace $s3Provider.namespace }}
{{- /* Build dict explicitly to ensure secretName is used */}}
{{- $s3Labels := merge (default dict $glyphDefinition.labels) (dict
  "kast.ing/s3-identity" "true"
  "kast.ing/s3-provider" $s3Provider.name
  "kast.ing/identity-name" $identityName
) }}
{{ include "vault.secret" (list $root (dict
  "name" $secretName
  "nameOverwrite" $name
  "format" "env"
  "randomKeys" (list "AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY")
  "staticData" (dict
    "AWS_ENDPOINT" $s3Provider.endpoint
    "AWS_REGION" (default "us-east-1" $s3Provider.region)
    "S3_BUCKET" $bucketName
  )
  "labels" $s3Labels
  "selector" $glyphDefinition.selector
  "passPolicyName" (default "short-policy" $glyphDefinition.passPolicyName)
  "refreshPeriod" $glyphDefinition.refreshPeriod
  "serviceAccount" $glyphDefinition.serviceAccount
  "role" $glyphDefinition.role
)) }}
{{- end }}

{{- /* 2. VaultSecret in PROVIDER NAMESPACE (for aggregation) */}}
{{- /* Clean dict with provider credentials only - no app glyphDefinition */}}
{{- /* Reads from same vault paths where RandomSecrets write (separate secrets per key) */}}
{{- /* Path: directory only (ending in /), name gets key suffix added by vault.secret */}}
{{ include "vault.secret" (list $root (dict
  "name" $secretName
  "nameOverwrite" $identityName
  "namespace" $s3Provider.namespace
  "format" "plain"
  "random" false
  "randomKeys" (list "AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY")
  "path" (printf "/%s/%s/%s/publics/" $root.Values.spellbook.name $root.Values.chapter.name $root.Release.Namespace)
  "staticData" (dict
    "IDENTITY_NAME" $identityName
    "PERMISSIONS" (join "," $permissions)
    "BUCKETS" (join "," $bucketPatterns)
  )
  "labels" (dict
    "kast.ing/s3-identity" "true"
    "kast.ing/s3-provider" $s3Provider.name
    "kast.ing/source-namespace" $root.Release.Namespace
    "kast.ing/identity-name" $identityName
  )
  "serviceAccount" $s3Provider.serviceAccount
  "role" $s3Provider.role
)) }}

{{- end }}
{{- end }}

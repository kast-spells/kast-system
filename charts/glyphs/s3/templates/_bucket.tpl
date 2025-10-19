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
{{- $permissions := default (list "Read" "Write") $glyphDefinition.permissions }}

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

{{- /* Vault path: s3-identities-PROVIDER-NAME in publics directory
     App has default access, aggregator uses extraPolicy wildcard */}}
{{- $secretName := printf "s3-identities-%s-%s" $s3Provider.name $name }}
{{- $vaultPath := printf "/%s/%s/%s/publics/%s" $root.Values.spellbook.name $root.Values.chapter.name (include "common.name" $root) $secretName }}

{{- /* 1. VaultSecret in APP NAMESPACE (for app consumption) */}}
{{- /* Use glyphDefinition as base, override only S3-specific settings */}}
{{- $s3Labels := merge (default dict $glyphDefinition.labels) (dict
  "kast.io/s3-identity" "true"
  "kast.io/s3-provider" $s3Provider.name
  "kast.io/identity-name" $identityName
) }}
{{ include "vault.secret" (list $root (merge $glyphDefinition (dict
  "name" $name
  "format" "env"
  "randomKeys" (list "AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY")
  "path" $vaultPath
  "staticData" (dict
    "AWS_ENDPOINT" $s3Provider.endpoint
    "AWS_REGION" (default "us-east-1" $s3Provider.region)
    "S3_BUCKET" $bucketName
  )
  "labels" $s3Labels
))) }}

{{- /* 2. VaultSecret in PROVIDER NAMESPACE (for aggregation) */}}
{{- /* Clean dict with provider credentials only - no app glyphDefinition */}}
{{- /* Reads from same vault path as app - DOES NOT generate secrets (app does that) */}}
{{ include "vault.secret" (list $root (dict
  "name" $identityName
  "namespace" $s3Provider.namespace
  "format" "plain"
  "random" false
  "keys" (list "AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY")
  "path" $vaultPath
  "staticData" (dict
    "IDENTITY_NAME" $identityName
    "PERMISSIONS" (join "," $permissions)
    "BUCKETS" (join "," $bucketPatterns)
  )
  "labels" (dict
    "kast.io/s3-identity" "true"
    "kast.io/s3-provider" $s3Provider.name
    "kast.io/source-namespace" $root.Release.Namespace
    "kast.io/identity-name" $identityName
  )
  "serviceAccount" $s3Provider.serviceAccount
  "role" $s3Provider.role
)) }}

{{- end }}
{{- end }}

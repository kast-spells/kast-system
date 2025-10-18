{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

S3 Glyph - Seamless S3 integration with automatic credential management

Supports two types:
1. bucket: For apps consuming S3 storage
2. seaweed: For SeaweedFS infrastructure setup

Usage in app spell:
glyphs:
  s3:
    my-data:
      type: bucket
      # Optional overrides:
      # bucket: custom-bucket-name  # default: {book}-{chapter}-{name}
      # permissions: ["Read", "Write", "List"]  # default: ["Read", "Write"]
      # pattern: true  # adds -* suffix: {bucket}-*
      # pattern: ["prefix-*", "*-suffix", "custom"]  # custom bucket patterns
      # selector: {provider: seaweedfs}  # default: {default: book}

App consumes via:
secrets:
  my-data:
    contentType: env

Usage in seaweedfs spell:
glyphs:
  s3:
    seaweedfs:
      type: seaweed
      # Automatically creates:
      # - EventSource (watching secrets)
      # - Sensor (triggering aggregator)
      # - ConfigMap (aggregator script)
      # - ServiceAccount + RBAC
      # - Prolicy (vault access)
*/}}

{{- define "s3.bucket" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 -}}
{{ include "s3.bucket.impl" (list $root $glyphDefinition) }}
{{- end -}}

{{- define "s3.seaweed" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 -}}
{{ include "s3.seaweed.impl" (list $root $glyphDefinition) }}
{{- end -}}

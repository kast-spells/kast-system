{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "crossplane.provider" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: {{ default (include "common.name" $root) $glyphDefinition.name }}
spec:
  package: {{ $glyphDefinition.providerURL }}
{{- end }}

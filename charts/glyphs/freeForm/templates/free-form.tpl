{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "freeForm.manifest" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
{{ toYaml $glyphDefinition.definition }}
{{- end }}
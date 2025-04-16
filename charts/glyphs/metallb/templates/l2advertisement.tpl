{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2025 laaledesiempre@disroot.org
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "metallb.l2advertisement" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: {{ default (include "common.name" $root ) $glyphDefinition.name }}
spec:
  ipAddressPools:
{{- range $addressPool := $glyphDefinition.addressPools }}
  - {{ $addressPool }}
{{- end }}
{{- if $glyphDefinition.nodes }}
  nodeSelectors:
{{- range $glyphDefinition.nodes }}
     - matchLabels:
         kubernetes.io/hostname: {{ . }}
{{- end }}
{{- end }}

{{- end }}

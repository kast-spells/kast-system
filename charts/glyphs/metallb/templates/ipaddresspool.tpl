{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2025 laaledesiempre@disroot.org
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "metallb.ipaddresspool" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: {{ default (include "common.name" $root ) $glyphDefinition.name }}
spec:
  addresses:
{{- range $glyphDefinition.addresses }}
  - {{ . }}
{{- end }}
  autoAssign: {{ default false $glyphDefinition.autoAssign }}
  avoidBuggyIPs: {{ default true $glyphDefinition.autoAssign }}
{{- with $glyphDefinition.serviceAllocation }}
{{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

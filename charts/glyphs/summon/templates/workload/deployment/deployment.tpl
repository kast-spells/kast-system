{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
 */}}
{{- define "summon.workload.deployment" -}}
{{- $root := . -}}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "common.name" $root }}
  labels:
    {{- include "common.all.labels" $root | nindent 4 }}
    {{- with $root.Values.workload.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $root.Values.workload.annotations }}
  annotations:
    {{- include "common.annotations" $root | nindent 4 }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if not $root.Values.autoscaling.enabled }}
  replicas: {{ default 1 $root.Values.workload.replicas }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "common.selectorLabels" $root | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "common.selectorLabels" $root | nindent 8 }}
      annotations:
        {{- include "summon.checksums.annotations" $root | nindent 8 }}
    spec:
      {{- if $root.Values.hostNetwork }}
      hostNetwork: {{ $root.Values.hostNetwork }}
      {{- end }}
      {{- if $root.Values.dnsPolicy }}
      dnsPolicy: {{ $root.Values.dnsPolicy }}
      {{- end }}
      {{- include "summon.common.podSpec" $root | nindent 6 }}
{{- end -}}

##TODO faltan los volumenes

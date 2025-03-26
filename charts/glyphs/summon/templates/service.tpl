{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
 */}}
{{- define "summon.service" }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ include "common.name" . }}
  labels:
    {{- include "common.labels" $ | nindent 4 }}
  {{- with .Values.service.annotations }}
  annotations:
    {{- .| toYaml | nindent 4 }}
  {{- end }}
spec:
  type: {{ default "ClusterIP" .Values.service.type }}
{{- if eq .Values.service.type "LoadBalancerSpecial"}}
## this is a placeholder
  loadBalancerIP: 1.2.3.4
  loadBalancerSourceRanges: #supported on EKS, GKS and AKS at least
    - 130.211.204.1/32 # loadBalancerSourceRanges defines the IP ranges that are allowed to access the load balancer
  healthCheckNodePort: 30000   # healthCheckNodePort defines the healthcheck node port for the LoadBalancer service type
{{- end }}
  ports:
  {{- if .Values.service.ports }}
    {{- range .Values.service.ports }}
    - port: {{ default 80 .port }}
      protocol: {{ default "TCP" .protocol }}
      name:  {{ default "http" .name }}
      targetPort: {{ default 80 (default .port .targetPort) }}
      {{- if .nodePort }}
      nodePort: {{ .nodePort }}
      {{- end }}
    {{- end }}
  {{- else }}
    - port: {{ default 80 .port }}
      protocol: {{ default "TCP" .protocol }}
      name:  {{ default "http" .name }}
  {{- end }}
  selector:
    {{- include "common.selectorLabels" $ | nindent 4 }}
{{- end}}

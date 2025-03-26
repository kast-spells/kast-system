{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
 */}}
{{- define "summon.autoscaling" }}
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "common.name" . }}
  labels:
  {{- include "common.labels" . | nindent 2}}
annotations:
{{- include "common.annotations" . | nindent 2}}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ template "common.name" . }}
  minReplicas: {{ default .Values.workload.autoscaling.minReplicas .Values.workload.replicas }}
  maxReplicas: {{ .Values.workload.autoscaling.maxReplicas }}
  metrics:
    {{- if .Values.workload.autoscaling.targetCPUUtilizationPercentage }}
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .Values.workload.autoscaling.targetCPUUtilizationPercentage }}
    {{- end }}
    {{- if .Values.workload.autoscaling.targetMemoryUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ .Values.workload.autoscaling.targetMemoryUtilizationPercentage }}
    {{- end }}
## TODO implementar behiviors
{{- end -}}

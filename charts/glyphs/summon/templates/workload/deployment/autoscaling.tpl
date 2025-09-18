{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
 */}}
{{- define "summon.autoscaling" }}
{{- $root := . }}
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "common.name" $root }}
  labels:
    {{- include "common.labels" $root | nindent 4}}
  annotations:
    {{- include "common.annotations" $root | nindent 4}}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ template "common.name" $root }}
  minReplicas: {{ default $root.Values.autoscaling.minReplicas $root.Values.workload.replicas }}
  maxReplicas: {{ $root.Values.autoscaling.maxReplicas }}
  metrics:
    {{- if $root.Values.autoscaling.targetCPUUtilizationPercentage }}
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ $root.Values.autoscaling.targetCPUUtilizationPercentage }}
    {{- end }}
    {{- if $root.Values.autoscaling.targetMemoryUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ $root.Values.autoscaling.targetMemoryUtilizationPercentage }}
    {{- end }}
  # TODO: implementar behaviors
{{- end -}}
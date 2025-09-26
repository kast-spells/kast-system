{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

summon.persistentVolumeClaim.single creates a single PersistentVolumeClaim resource.
Does NOT iterate - generates exactly one PVC for the provided volume definition.

Parameters: (list $root $volumeName $volumeDefinition)
- $root: Chart root context
- $volumeName: Name/key of the volume (used for default naming)
- $volumeDefinition: Volume configuration object

Volume Configuration:
- volume.name: optional custom PVC name (defaults to {chart-name}-{volumeName})
- volume.size: required storage size (e.g., "10Gi")
- volume.storageClassName: optional storage class
- volume.accessMode: optional access mode (defaults to "ReadWriteOnce")
- volume.labels: optional additional labels
- volume.annotations: optional additional annotations

Usage: 
- {{- include "summon.persistentVolumeClaim.single" (list $ "data" $volumeDef) }}
*/}}

{{/* PVC generator - creates exactly one PVC without iteration */}}
{{- define "summon.persistentVolumeClaim" -}}
{{- $root := index . 0 }}
{{- $volumeName := index . 1 }}
{{- $volume := index . 2 }}
{{- $baseName := default (include "common.name" $root) (index . 3) }}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  {{- $pvcName := "" }}
  {{- if $volume.name }}
    {{- $pvcName = $volume.name }}
  {{- else }}
    {{- $pvcName = print $baseName "-" $volumeName }}
  {{- end }}
  name: {{ $pvcName }}
  labels:
    {{- include "common.labels" $root | nindent 4}}
    {{- with $volume.labels }}
    {{ toYaml . | nindent 4 }}
    {{- end }}
  annotations:
    {{- include "common.annotations" $root | nindent 4}}
    {{- with $volume.annotations }}
    {{ toYaml . | nindent 4 }}
    {{- end }}
spec:
  
  {{- if $volume.volumeName }}
  volumeName: {{ $volume.volumeName }}
  {{- end }}
  {{- if $volume.storageClassName }}
  storageClassName: {{ $volume.storageClassName }}
  {{- end }}
  accessModes: 
    - {{ default "ReadWriteOnce" $volume.accessMode }}
  resources:
    requests:
      storage: {{ default "1Gi" $volume.size }}
{{- end }}
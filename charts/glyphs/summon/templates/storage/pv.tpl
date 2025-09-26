{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

summon.pv generates PersistentVolume resources for custom storage backends like CSI.
Follows standard glyph parameter pattern for consistency.

Parameters:
- $root: Chart root context
- $name: Volume name
- $volume: Volume configuration with PV details

Usage: {{- include "summon.pv" (list $root $name $volume) }}
*/}}
{{- define "summon.pv" }}
{{- $root := index . 0 }}
{{- $name := index . 1 }}
{{- $volume := index . 2 }}
{{- $baseName := default (include "common.name" $root) (index . 3) }}
---
apiVersion: v1
kind: PersistentVolume
metadata:
  {{- $pvName := "" }}
  {{- if $volume.volumeName }}
    {{/* Priority 1: explicit volumeName overrides everything */}}
    {{- $pvName = $volume.volumeName }}
  {{- else if $volume.name }}
    {{/* Priority 2: if name is defined, use it directly */}}
    {{- $pvName = $volume.name }}
  {{- else }}
    {{/* Priority 3: default to app-name + volume-key */}}
    {{- $pvName = printf "%s-%s" $baseName $name }}
  {{- end }}
  name: {{ $pvName }}
  labels:
    {{- include "common.labels" $root | nindent 4 }}
    volume: {{ $name }}
spec:
  {{- if $volume.storageClass }}
  storageClassName: {{ $volume.storageClass }}
  {{- end }}
  capacity:
    storage: {{ default "10Gi" $volume.size }}
  accessModes:
    - {{ default "ReadWriteOnce" $volume.accessMode }}
  {{- if $volume.persistentVolumeReclaimPolicy }}
  persistentVolumeReclaimPolicy: {{ $volume.persistentVolumeReclaimPolicy }}
  {{- else }}
  persistentVolumeReclaimPolicy: Retain
  {{- end }}
  {{- with $volume.pv }}
  csi:
    driver: {{ .driver }}
    {{- if .volumeHandle }}
    volumeHandle: {{ .volumeHandle }}
    {{- else }}
    volumeHandle: {{ include "common.name" $root }}-{{ $name }}
    {{- end }}
    {{- if .fsType }}
    fsType: {{ .fsType }}
    {{- end }}
    {{- if .readOnly }}
    readOnly: {{ .readOnly }}
    {{- end }}
    {{- if .volumeAttributes }}
    volumeAttributes:
      {{- range $key, $value := .volumeAttributes }}
      {{ $key }}: {{ $value | quote }}
      {{- end }}
    {{- end }}
    {{- if .nodeStageSecretRef }}
    nodeStageSecretRef:
      name: {{ .nodeStageSecretRef.name }}
      namespace: {{ .nodeStageSecretRef.namespace | default $root.Release.Namespace }}
    {{- end }}
    {{- if .nodePublishSecretRef }}
    nodePublishSecretRef:
      name: {{ .nodePublishSecretRef.name }}
      namespace: {{ .nodePublishSecretRef.namespace | default $root.Release.Namespace }}
    {{- end }}
    {{- if .controllerPublishSecretRef }}
    controllerPublishSecretRef:
      name: {{ .controllerPublishSecretRef.name }}
      namespace: {{ .controllerPublishSecretRef.namespace | default $root.Release.Namespace }}
    {{- end }}
    {{- if .controllerExpandSecretRef }}
    controllerExpandSecretRef:
      name: {{ .controllerExpandSecretRef.name }}
      namespace: {{ .controllerExpandSecretRef.namespace | default $root.Release.Namespace }}
    {{- end }}
  {{- end }}
{{- end }}
{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

summon.pv generates PersistentVolume resources for custom storage backends (CSI, local, etc).
Follows standard glyph parameter pattern for consistency.

Parameters:
- $root: Chart root context
- $name: Volume name
- $volume: Volume configuration with PV details

Backend Types:
- local: Use .pv.path to trigger local backend
  Example:
    pv:
      path: /storage/weedfs
      type: Directory  # optional: Directory, DirectoryOrCreate, etc
      nodeAffinity:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/hostname
            operator: In
            values: [node-name]

- csi: Use .pv.driver to trigger CSI backend
  Example:
    pv:
      driver: ru.yandex.s3.csi
      volumeHandle: bucket-name
      volumeAttributes: {...}

Usage: {{- include "summon.pv" (list $root $name $volume) }}
*/}}
{{- define "summon.pv" }}
{{- $root := index . 0 }}
{{- $name := index . 1 }}
{{- $volume := index . 2 }}
{{- $baseName := default (include "common.name" $root) (index . 3) }}
{{/* Use Runic Indexer to find CSI configuration from lexicon */}}
{{- $csiConfig := dict }}
{{- if $root.Values.lexicon }}
  {{- if $volume.storageClass }}
    {{/* Try to find by storageClass label first */}}
    {{- $selectors := dict "storageClass" $volume.storageClass }}
    {{- $runicResult := include "runicIndexer.runicIndexer" (list $root.Values.lexicon $selectors "csi-config" ($root.Values.chapter.name | default "")) | fromJson }}
    {{- if $runicResult.results }}
      {{- $csiConfig = first $runicResult.results }}
    {{- else }}
      {{/* If no match by storageClass, try default (empty selector to get default: book) */}}
      {{- $runicResult = include "runicIndexer.runicIndexer" (list $root.Values.lexicon (dict) "csi-config" ($root.Values.chapter.name | default "")) | fromJson }}
      {{- if $runicResult.results }}
        {{- $csiConfig = first $runicResult.results }}
      {{- end }}
    {{- end }}
  {{- else }}
    {{/* No storageClass specified, use default csi-config */}}
    {{- $runicResult := include "runicIndexer.runicIndexer" (list $root.Values.lexicon (dict) "csi-config" ($root.Values.chapter.name | default "")) | fromJson }}
    {{- if $runicResult.results }}
      {{- $csiConfig = first $runicResult.results }}
    {{- end }}
  {{- end }}
{{- end }}
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
    {{- include "common.all.labels" $root | nindent 4 }}
    volume: {{ $name }}
    {{- with $volume.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $volume.annotations }}
  annotations:
    {{- include "common.annotations" $root | nindent 4 }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if hasKey $volume "storageClass" }}
  storageClassName: {{ $volume.storageClass | quote }}
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
  {{- if .path }}
  {{/* Local PersistentVolume backend */}}
  local:
    path: {{ .path }}
  {{- if .nodeAffinity }}
  nodeAffinity:
    {{- toYaml .nodeAffinity | nindent 4 }}
  {{- end }}
  {{- else if or .driver .volumeHandle $csiConfig.driver }}
  {{/* CSI PersistentVolume backend - triggered by .driver OR .volumeHandle OR lexicon csi-config */}}
  csi:
    {{/* Use driver from lexicon if available, otherwise use provided, otherwise fail */}}
    {{- $driver := $csiConfig.driver | default .driver }}
    {{- if not $driver }}
      {{- if $volume.storageClass }}
        {{- fail (printf "CSI driver not found for storageClass '%s'. Options: 1) Add pv.driver field, 2) Add lexicon entry with type 'csi-config' and labels.storageClass='%s', 3) Add default lexicon entry with type 'csi-config' and labels.default='book'" $volume.storageClass $volume.storageClass) }}
      {{- else }}
        {{- fail "CSI driver not found. Options: 1) Add pv.driver field, 2) Specify storageClass, 3) Add default lexicon entry with type 'csi-config' and labels.default='book'" }}
      {{- end }}
    {{- end }}
    driver: {{ $driver }}
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
    {{/* Merge volumeAttributes from lexicon defaults and user provided */}}
    {{- $finalAttributes := dict }}
    {{- if $csiConfig.defaultAttributes }}
      {{- range $key, $value := $csiConfig.defaultAttributes }}
        {{- $_ := set $finalAttributes $key $value }}
      {{- end }}
    {{- end }}
    {{- if .volumeAttributes }}
      {{- range $key, $value := .volumeAttributes }}
        {{- $_ := set $finalAttributes $key $value }}
      {{- end }}
    {{- end }}
    {{- if $finalAttributes }}
    volumeAttributes:
      {{- range $key, $value := $finalAttributes }}
      {{ $key }}: {{ $value | quote }}
      {{- end }}
    {{- end }}
    {{/* Use secretRefs from lexicon if not provided by user */}}
    {{- if or .nodeStageSecretRef (and $csiConfig.secretRefs $csiConfig.secretRefs.nodeStageSecretRef) }}
    nodeStageSecretRef:
      {{- if .nodeStageSecretRef }}
      name: {{ .nodeStageSecretRef.name }}
      namespace: {{ .nodeStageSecretRef.namespace | default $root.Release.Namespace }}
      {{- else if and $csiConfig.secretRefs $csiConfig.secretRefs.nodeStageSecretRef }}
      name: {{ $csiConfig.secretRefs.nodeStageSecretRef.name }}
      namespace: {{ $csiConfig.secretRefs.nodeStageSecretRef.namespace | default $root.Release.Namespace }}
      {{- end }}
    {{- end }}
    {{- if or .nodePublishSecretRef (and $csiConfig.secretRefs $csiConfig.secretRefs.nodePublishSecretRef) }}
    nodePublishSecretRef:
      {{- if .nodePublishSecretRef }}
      name: {{ .nodePublishSecretRef.name }}
      namespace: {{ .nodePublishSecretRef.namespace | default $root.Release.Namespace }}
      {{- else if and $csiConfig.secretRefs $csiConfig.secretRefs.nodePublishSecretRef }}
      name: {{ $csiConfig.secretRefs.nodePublishSecretRef.name }}
      namespace: {{ $csiConfig.secretRefs.nodePublishSecretRef.namespace | default $root.Release.Namespace }}
      {{- end }}
    {{- end }}
    {{- if or .controllerPublishSecretRef (and $csiConfig.secretRefs $csiConfig.secretRefs.controllerPublishSecretRef) }}
    controllerPublishSecretRef:
      {{- if .controllerPublishSecretRef }}
      name: {{ .controllerPublishSecretRef.name }}
      namespace: {{ .controllerPublishSecretRef.namespace | default $root.Release.Namespace }}
      {{- else if and $csiConfig.secretRefs $csiConfig.secretRefs.controllerPublishSecretRef }}
      name: {{ $csiConfig.secretRefs.controllerPublishSecretRef.name }}
      namespace: {{ $csiConfig.secretRefs.controllerPublishSecretRef.namespace | default $root.Release.Namespace }}
      {{- end }}
    {{- end }}
    {{- if or .controllerExpandSecretRef (and $csiConfig.secretRefs $csiConfig.secretRefs.controllerExpandSecretRef) }}
    controllerExpandSecretRef:
      {{- if .controllerExpandSecretRef }}
      name: {{ .controllerExpandSecretRef.name }}
      namespace: {{ .controllerExpandSecretRef.namespace | default $root.Release.Namespace }}
      {{- else if and $csiConfig.secretRefs $csiConfig.secretRefs.controllerExpandSecretRef }}
      name: {{ $csiConfig.secretRefs.controllerExpandSecretRef.name }}
      namespace: {{ $csiConfig.secretRefs.controllerExpandSecretRef.namespace | default $root.Release.Namespace }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- end }}
{{- end }}
{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "gcp.vm" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeInstance
metadata:
  labels:
    {{- include "common.infra.labels" $root | nindent 4}}
  name: {{ default (include "common.name" $root) $glyphDefinition.name }}
  annotations:
    {{- include "common.infra.annotations" $root | nindent 4}}
spec:
  machineType: {{ default "e2-micro" $glyphDefinition.machineType }}
  zone: {{ $glyphDefinition.zone }}
  canIpForward: {{ default false $glyphDefinition.canIpForward }}
  description: {{ default $glyphDefinition.name $glyphDefinition.description }}
  {{- if $glyphDefinition.hostname }}
  hostname: {{ $glyphDefinition.hostname }}
  {{- end }}
  metadataStartupScript: {{ $glyphDefinition.script }}
  bootDisk:
    autoDelete: {{ default "false" $glyphDefinition.autoDelete }}
    initializeParams:
      size: {{ default 10 $glyphDefinition.diskSize }}
      type: {{ default "pd-ssd" $glyphDefinition.diskType }}
      sourceImageRef:
        external: {{ default "debian-cloud/debian-12" $glyphDefinition.image }}
  networkInterface:
    - accessConfig:
        - networkTier: {{ default "STANDARD" $glyphDefinition.netTier }}
          natIpRef:
            name: {{ $glyphDefinition.natIpRef }}
            {{- if $glyphDefinition.natIpRefNamespace }}
            namespace: {{ $glyphDefinition.natIpRefNamespace }}
            {{- end }}
      stackType: IPV4_ONLY
      subnetworkRef:
        name: {{ $glyphDefinition.subnetworkRef }}
        {{- if $glyphDefinition.subnetworkRefNamespace }}
        namespace: {{ $glyphDefinition.subnetworkRefNamespace }}
        {{- end }}
  scheduling:
    automaticRestart: true
  tags:
  {{ range $glyphDefinition.tags }}
    - {{ . }}
  {{- end }}
{{- end }}

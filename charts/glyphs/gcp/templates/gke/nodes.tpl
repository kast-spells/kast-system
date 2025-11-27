{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "gcp.nodes" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: container.cnrm.cloud.google.com/v1beta1
kind: ContainerNodePool
metadata:
  name: {{ default (include "common.name" $root) $glyphDefinition.name }}
  labels:
    {{- include "common.all.labels" $root | nindent 4 }}
    {{- with $glyphDefinition.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $glyphDefinition.annotations }}
  annotations:
    {{- include "common.annotations" $root | nindent 4 }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  clusterRef:
    name: {{ $glyphDefinition.clusterRef }}
    {{- if $glyphDefinition.clusterRefNamespace }}
    namespace: {{ $glyphDefinition.clusterRefNamespace }}
    {{- end }}
  location: {{ $glyphDefinition.region }}
  nodeCount: {{ default "2" $glyphDefinition.startingNodes }}
  # maxPodsPerNode: 500
  autoscaling:
    minNodeCount: {{ default "1" $glyphDefinition.minNodeCount }}
    maxNodeCount: {{ default "10" $glyphDefinition.maxNodeCount }}
  networkConfig:
    # additionalNodeNetworkConfigs:
    # - networkRef:
    #     external: string
    #     name: string
    #     namespace: string
    #   subnetworkRef:
    #     external: string
    #     name: string
    #     namespace: string
    # additionalPodNetworkConfigs:
    # - maxPodsPerNode: integer
    #   secondaryPodRange: string
    #   subnetworkRef:
    #     external: string
    #     name: string
    #     namespace: string
    # createPodRange: true
    enablePrivateNodes: {{ default true $glyphDefinition.enablePrivateNodes }}
    # podCidrOverprovisionConfig:
    #   disabled: boolean
    # podIpv4CidrBlock: 10.201.0.0/16
    # podRange: string
  management:
    autoRepair: {{ default true $glyphDefinition.autoRepair }}
    autoUpgrade: {{ default true $glyphDefinition.autoUpgrade }}
  nodeConfig:
    spot: {{ default true $glyphDefinition.spot }}
    machineType: {{ default "e2-highcpu-4" $glyphDefinition.machineType }}
    diskSizeGb: {{ default 25 $glyphDefinition.diskSizeGb }}
    diskType: {{ default "pd-standard" $glyphDefinition.diskType }}
    # tags:
    #   - tagone
    #   - tagtwo
    # oauthScopes:
    #   - "https://www.googleapis.com/auth/logging.write"
    #   - "https://www.googleapis.com/auth/monitoring"
    metadata:
      disable-legacy-endpoints: {{ default true $glyphDefinition.noLegacyEndpoints }}
{{- end }}
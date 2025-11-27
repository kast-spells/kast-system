{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "gcp.cluster" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
{{- $podCIDR := default "10.200.0.0/16" $glyphDefinition.podCIDR }}
apiVersion: container.cnrm.cloud.google.com/v1beta1
kind: ContainerCluster
metadata:
  name: {{ default (include "common.name" $root) $glyphDefinition.name }}
  labels:
    {{- include "common.all.labels" $root | nindent 4 }}
    {{- with $glyphDefinition.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $glyphDefinition.annotations }}
  annotations:
    cnrm.cloud.google.com/remove-default-node-pool: "true"
    {{- include "common.annotations" $root | nindent 4 }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  description: {{ default $glyphDefinition.name $glyphDefinition.description }}
  location: {{ $glyphDefinition.region }}
  {{- if $glyphDefinition.nodeLocations }}
  nodeLocations:
    {{- range $glyphDefinition.nodeLocations }}
    - {{ . }}
    {{- end }}
  {{- else }}
  nodeLocations:
    - us-east5-a
  {{- end }}
  workloadIdentityConfig:
    workloadPool: the-yaml-life.svc.id.goog
  networkingMode: {{ default "routes" $glyphDefinition.description }}
  networkRef:
    name: {{ $glyphDefinition.networkRef }}
    {{- if $glyphDefinition.networkRefNamespace }}
    namespace: {{ $glyphDefinition.networkRefNamespace }}
    {{- end }}
  subnetworkRef:
    name: {{ $glyphDefinition.subnetworkRef }}
    {{- if $glyphDefinition.subnetworkRefNamespace }}
    namespace: {{ $glyphDefinition.subnetworkRefNamespace }}
    {{- end }}
  {{- if not $glyphDefinition.public }}
  privateClusterConfig:
    enablePrivateEndpoint: true
    enablePrivateNodes: true
    masterGlobalAccessConfig:
      enabled: false
    masterIpv4CidrBlock: {{ $glyphDefinition.masterCIDR }}
    # peeringName: string
    # privateEndpoint: string
    # privateEndpointSubnetworkRef:
    #   external: string
    #   name: string
    #   namespace: string
    # publicEndpoint: string
  masterAuthorizedNetworksConfig:
    {{ $cidrs := append $glyphDefinition.masterAuthCidrs (dict "displayName" "pods" "cidrBlock" $podCIDR )}}
    cidrBlocks:
    {{- range $cidrs }}
      - {{ toYaml . }}
    {{- end  }}
    gcpPublicCidrsAccessEnabled: false
  {{- end }}
  # maintenancePolicy:
  #   dailyMaintenanceWindow:
  #     startTime: 00:00
  releaseChannel:
    channel: {{ default "STABLE" $glyphDefinition.releaseChannel }}
  clusterIpv4Cidr: {{ $podCIDR }}
  # loggingService: none
  # monitoringService: none
  # servicesIpv4Cidr: 10.201.0.0/16
  enableBinaryAuthorization: false
  enableIntranodeVisibility: false
  enableShieldedNodes: true
  {{- if not $glyphDefinition.monitoring }}
  loggingConfig:
    enableComponents: []
  monitoringConfig:
    advancedDatapathObservabilityConfig:
    - enableMetrics: false
    managedPrometheus:
      enabled: false
  {{- end }}
  addonsConfig:
    networkPolicyConfig:
      disabled: false
    dnsCacheConfig:
      enabled: true
    configConnectorConfig:
      enabled: false
  networkPolicy:
    enabled: true
  podSecurityPolicyConfig:
    enabled: false
  verticalPodAutoscaling:
    enabled: true
  initialNodeCount: 1
  # clusterAutoscaling:
  #   enabled: true
  #   autoscalingProfile: OPTIMIZE_UTILIZATION
  #   resourceLimits:
  #   - resourceType: cpu
  #     maximum: 100
  #     minimum: 10
  #   - resourceType: memory
  #     maximum: 1000
  #     minimum: 100
  nodeConfig: 
    diskSizeGb: 25
    diskType: pd-standard
    machineType: e2-highcpu-2
    spot: true
{{- end }}

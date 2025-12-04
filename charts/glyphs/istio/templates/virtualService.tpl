{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

istio.virtualService creates Istio VirtualService resources for routing traffic to services.
Integrates with the runicIndexer system to find appropriate gateways based on selectors.

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: VirtualService configuration object (index . 1)

Required Configuration:
- glyphDefinition.enabled: must be true to generate resource

Optional Configuration:
- glyphDefinition.nameOverride: custom resource name (defaults to common.name + gateway.name)
- glyphDefinition.namespace: target namespace
- glyphDefinition.subdomain: subdomain for routing (inherits from spellbook/chapter)
- glyphDefinition.selector: selector for runicIndexer to find gateways
- glyphDefinition.httpRules: HTTP routing rules array
- glyphDefinition.tcpRules: TCP routing rules array  
- glyphDefinition.host: target service host (defaults to common.name.namespace.svc.cluster.local)
- glyphDefinition.prefix: URL prefix for routing (defaults to /{common.name})
- glyphDefinition.rewrite: URL rewrite target (defaults to "/")

Usage: {{- include "istio.virtualService" (list $root $glyph) }}
*/}}
{{- define "istio.virtualService" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
{{- if $glyphDefinition.enabled }}
{{- $gateways := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.selector) "istio-gw" $root.Values.chapter.name ) | fromJson) "results" }}
{{- range $gateway := $gateways }}
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: {{ default (include "common.name" $root ) $glyphDefinition.nameOverride }}-{{ $gateway.name }}
  labels:
    {{- include "common.labels" $root | nindent 4 }}
{{- if $glyphDefinition.namespace }}
  namespace: {{ $glyphDefinition.namespace }}
{{- end }}
spec:
  hosts:
    - {{ if default (default $root.Values.spellbook.subdomain $root.Values.chapter.subdomain) $glyphDefinition.subdomain }}{{ default (default $root.Values.spellbook.subdomain $root.Values.chapter.subdomain) $glyphDefinition.subdomain }}.{{ end }}{{ $gateway.baseURL  }}
  gateways:
    - {{ $gateway.gateway }}
  {{- if and (not $glyphDefinition.httpRules ) (not $glyphDefinition.tcpRules) }}
  {{- $defaultRule := list (dict "default" "default") }}
  {{- $_ := merge $glyphDefinition (dict "httpRules" $defaultRule) }}
  {{- end }}
  {{- with $glyphDefinition.httpRules }}
  http:
  {{- range $httpRule := . }}
    - match:
      - uri:
          prefix: {{ default (default (printf "/%s" ( include "common.name" $root )) $glyphDefinition.prefix) $httpRule.prefix }}
      {{- if or $glyphDefinition.rewrite $httpRule.rewrite }}
      rewrite:
        uri: {{ default (default "/" $glyphDefinition.rewrite) $httpRule.rewrite }}
      {{- end }}
      route:
        - destination:
            host: {{ if (default $glyphDefinition.host $httpRule.host) }}{{ (default $glyphDefinition.host $httpRule.host) }}{{ else }}{{ include "common.name" $root }}.{{ $root.Release.Namespace }}.svc.cluster.local{{ end }}
            port:
              number: {{ default "80" $httpRule.port }}
      {{- end }}
  {{- end }}
  {{- with $glyphDefinition.tcpRules }}
  tcp:
  {{- range $tcpRule := . }}
    - match:
      - port: {{ default $tcpRule.port $tcpRule.incomingPort }}
      route:
        - destination:
            host: {{ if (default $glyphDefinition.host $tcpRule.host) }}{{ (default $glyphDefinition.host $tcpRule.host) }}{{ else }}{{ include "common.name" $root }}.{{ $root.Release.Namespace }}.svc.cluster.local{{ end }}
            port:
              number: {{ default "80" $tcpRule.port }}
      {{- end }}
  {{- end }}
  {{- end }}
{{- end }}
{{- end }}

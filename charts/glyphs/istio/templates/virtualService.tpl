{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "istio.virtualService" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
{{- if $glyphDefinition.enabled }}
{{- $gateways := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.selector) "istio-gw" $root.Values.chapter.name ) | fromJson) "results" }}
{{- range $gateway := $gateways }}
---
apiVersion: networking.istio.io/v1alpha3
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
    - {{ if default $glyphDefinition.subdomain (default $root.Values.spellbook.subdomain $root.Values.chapter.subdomain ) }}{{ default $glyphDefinition.subdomain (default $root.Values.spellbook.subdomain $root.Values.chapter.subdomain ) }}.{{ end }}{{ $gateway.baseURL  }}
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

{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "istio.istio-gw" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}
---
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: {{ default (include "common.name" $root) $glyphDefinition.name }}
  labels:
    {{- include "common.labels" $root | nindent 4 }}
  {{- with $glyphDefinition.annotations }}
  annotations:
  {{ . | toYaml | nindent 4 }}
  {{- end }}
spec:
  selector:
    {{- if $glyphDefinition.istioSelector }}
    {{- $glyphDefinition.istioSelector | toYaml | nindent 4 }}
    {{- else }}
    istio: {{ default (include "common.name" $root) $glyphDefinition.name }}
    {{- end }}
  servers:
  {{- $defaultPorts := list (dict "name" "http" "port" 80 "protocol" "HTTP") (dict "name" "https" "port" 443 "protocol" "HTTPS") -}}
  {{- range $port := (default $defaultPorts $glyphDefinition.ports) }}
    - port:
        number: {{ $port.port }}
        name:  {{ $port.port }}-{{ $port.protocol }}
        protocol: {{ $port.protocol }}
      hosts:
      {{- range $host := $glyphDefinition.hosts }}
        - "{{ $host }}"
      {{- end }}
    {{- if not $glyphDefinition.tls }}
    {{- $glyphDefinition = merge $glyphDefinition (dict "tls" (dict "enabled" true)) }}
    {{- end }}
    {{- if $glyphDefinition.tls.enabled }}
        {{- if (eq $port.protocol "HTTPS") }}
      tls:
        mode: SIMPLE
        credentialName: {{ default ( print (include "common.name" $root ) "-" $glyphDefinition.tls.issuerName "-cert" ) $glyphDefinition.tls.secretName }}
        {{- end }}
        {{- if and (eq $port.protocol "HTTP" ) (default "True" $port.httpsRedirect) }}
      tls:
        httpsRedirect: true # sends 301 redirect for http requests
        {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

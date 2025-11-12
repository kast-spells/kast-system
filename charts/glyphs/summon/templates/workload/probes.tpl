{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
 */}}
{{- define "summon.common.workload.probes" -}}
{{- if gt (len .) 0 -}}
{{- range $probe, $pDef := . }}
{{ $probe }}Probe:
{{- if eq $pDef.type "httpGet" }}
  httpGet:
    path: {{ $pDef.path }}
    port: {{ $pDef.port }}
    scheme: {{ $pDef.scheme }}
    {{- with $pDef.httpHeaders }}
    httpHeaders:
    {{- range . }}
      - name: {{ .name }}
        value: {{ .value }}
    {{- end }}
    {{- end }}
{{- end }}
{{- if eq $pDef.type "tcpSocket"}}
  tcpSocket:
    port: {{ $pDef.port }}
{{- end }}
{{- if eq $pDef.type "exec" }}
  exec:
    command: {{- toYaml $pDef.command | nindent 6 }}
{{- end }}
{{- if $pDef.initialDelaySeconds }}
  initialDelaySeconds: {{ $pDef.initialDelaySeconds }}
{{- end }}
{{- if $pDef.periodSeconds }}
  periodSeconds: {{ $pDef.periodSeconds }}
{{- end }}
{{- if $pDef.timeoutSeconds }}
  timeoutSeconds: {{ $pDef.timeoutSeconds }}
{{- end }}
{{- if $pDef.successThreshold }}
  successThreshold: {{ $pDef.successThreshold }}
{{- end }}
{{- if $pDef.failureThreshold }}
  failureThreshold: {{ $pDef.failureThreshold }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}
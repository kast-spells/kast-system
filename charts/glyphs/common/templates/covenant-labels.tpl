{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}

{{/*
Covenant Identity & Access Management Labels
These labels are used for tracking identity and access management resources.
Enable via: .Values.labels.covenant.enabled

These labels support:
- User and member tracking
- Team and organizational structure
- Integration and client identification
- Access control and permissions

Usage in values.yaml:
  labels:
    covenant:
      enabled: true
      team: platform-team
      owner: john.doe@company.com
      department: engineering
      member: john-doe
      organization: my-org
*/}}
{{- define "common.covenant.labels" -}}
{{- if .Values.labels }}
{{- if .Values.labels.covenant }}
{{- if .Values.labels.covenant.enabled }}
{{- with .Values.labels.covenant.team }}
covenant.kast.io/team: {{ . }}
{{- end }}
{{- with .Values.labels.covenant.owner }}
covenant.kast.io/owner: {{ . }}
{{- end }}
{{- with .Values.labels.covenant.department }}
covenant.kast.io/department: {{ . }}
{{- end }}
{{- with .Values.labels.covenant.member }}
covenant.kast.io/member: {{ . }}
{{- end }}
{{- with .Values.labels.covenant.organization }}
covenant.kast.io/organization: {{ . }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*runik - Kubernetes arcane spelling technology
Copyright (C) 2025 namenmalkav@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

Main orchestrator for dataStore.psql feature
Detects strategy (managed vs external) and delegates to appropriate templates
*/}}

{{- if .Values.dataStore.psql.enabled }}

{{- if eq (include "microspell.psql.isExternal" .) "true" }}
  {{/*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/}}
  {{/* EXTERNAL CLUSTER (has selector)   */}}
  {{/*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/}}

  {{- include "microspell.psql.external" . }}

{{- else }}
  {{/*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/}}
  {{/* MANAGED CLUSTER (no selector)     */}}
  {{/*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/}}

  {{- include "microspell.psql.managed" . }}

{{- end }}

{{- end }}

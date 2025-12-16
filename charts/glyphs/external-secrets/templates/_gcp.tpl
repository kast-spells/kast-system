{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2025 laaledesiempre@disroot.org
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}

{{- define "gcp.secretPath" }}
{{- /* gcp.secretPath generates GCP Secret Manager specific secret paths.

GCP Secret Manager does not allow secret names starting with '/'.
This helper strips any leading slash from the generated path.

Parameters:
- $root: Chart root context (index . 0)
- $glyph: Glyph definition object (index . 1)
- $options: Optional dict (index . 2)

Options dict:
- excludeName: bool - If true, don't append name to path (for create operations)

GCP-specific behavior:
- Strips leading '/' from all paths (GCP requirement)
- basePath is empty "" for GCP (no prefix needed)

Examples:
  {{- include "gcp.secretPath" (list $root (dict "name" "api-key" "path" "book") dict) }}
  → my-book/publics/api-key

  {{- include "gcp.secretPath" (list $root (dict "name" "db-creds" "path" "/production/keys") dict) }}
  → production/keys/db-creds
*/}}
  {{- $root := index . 0 }}
  {{- $glyph := index . 1 }}
  {{- $options := dict }}
  {{- if gt (len .) 2 }}
    {{- $options = index . 2 }}
  {{- end }}

  {{- /* GCP uses empty basePath (no prefix) */ -}}
  {{- $basePath := "" }}

  {{- /* Generate path using common helper */ -}}
  {{- $generatedPath := include "common.secretPath" (list $root $glyph $basePath $options) }}

  {{- /* GCP-specific: Strip leading slash */ -}}
  {{- trimPrefix "/" $generatedPath }}
{{- end }}

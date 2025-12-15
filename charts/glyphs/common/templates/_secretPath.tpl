{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2025 laaledesiempre@disroot.org
Licensed under the GNU GPL v3. See LICENSE file for details.

common.secretPath generates basic hierarchical secret paths.

This is a PROVIDER-AGNOSTIC helper. Provider-specific logic (like Vault's /data prefix,
AWS region handling, etc.) should be in the respective provider glyph.

Parameters:
- $root: Chart root context (index . 0)
- $glyph: Glyph definition object (index . 1)
- $basePath: Base path string from provider config (index . 2)
- $options: Optional dict (index . 3)

Options dict:
- excludeName: bool - If true, don't append name to path (for create operations)

Path Resolution:
- path: "book" → {basePath}/{spellbook}/{visibility}/{name}
- path: "chapter" → {basePath}/{spellbook}/{chapter}/{visibility}/{name}
- path: "/absolute/path/" → {basePath}/absolute/path/{name}
- path: "/absolute/path" → {basePath}/absolute/path
- default → {basePath}/{spellbook}/{chapter}/{namespace}/{visibility}/{name}

Visibility:
- Default: "publics"
- Override via glyph.private: "privates"

Examples:
  {{- include "common.secretPath" (list $root (dict "name" "api-key" "path" "book") "kv" dict) }}
  → kv/my-book/publics/api-key

  {{- include "common.secretPath" (list $root (dict "name" "db-creds" "path" "chapter") "kv" dict) }}
  → kv/my-book/prod/publics/db-creds

  {{- include "common.secretPath" (list $root (dict "name" "cert" "path" "/ssl/certs") "kv" dict) }}
  → kv/ssl/certs/cert

  {{- include "common.secretPath" (list $root (dict "name" "api-secret") "kv" dict) }}
  → kv/my-book/prod/default/publics/api-secret
*/}}

{{- define "common.secretPath" }}
  {{- $root := index . 0 }}
  {{- $glyph := index . 1 }}
  {{- $basePath := index . 2 }}
  {{- $options := dict }}
  {{- if gt (len .) 3 }}
    {{- $options = index . 3 }}
  {{- end }}

  {{- $visibility := default "publics" $glyph.private }}
  {{- $path := default "" $glyph.path }}
  {{- $name := $glyph.name }}

  {{- if $options.excludeName }}
    {{- $name = "" }}
  {{- end }}

  {{- /* Simple hierarchical path generation */ -}}
  {{- if eq $path "book" }}
    {{- printf "%s/%s/%s/%s"
        $basePath
        $root.Values.spellbook.name
        $visibility
        $name }}
  {{- else if eq $path "chapter" }}
    {{- printf "%s/%s/%s/%s/%s"
        $basePath
        $root.Values.spellbook.name
        $root.Values.chapter.name
        $visibility
        $name }}
  {{- else if hasPrefix "/" $path }}
    {{- /* Absolute path */ -}}
    {{- if hasSuffix "/" $path }}
      {{- printf "%s%s%s" $basePath $path $name }}
    {{- else }}
      {{- printf "%s%s" $basePath $path }}
    {{- end }}
  {{- else }}
    {{- /* Default: book/chapter/namespace/visibility/name */ -}}
    {{- printf "%s/%s/%s/%s/%s/%s"
        $basePath
        $root.Values.spellbook.name
        $root.Values.chapter.name
        $root.Release.Namespace
        $visibility
        $name }}
  {{- end }}
{{- end }}

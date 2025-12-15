{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
## TODO tecnicamente problemas del secops del maniana, todo se genera en el ns de vault con la sa de vault problema del huevo y la gallina
 */}}
{{- define "vault.connect" -}}
  {{- $context := . -}}
  {{- $root := index $context 0 -}}
  {{- $vaultConf := index $context 1 -}}
  {{- $forceVault := (default "" (index $context 2)) -}}
  {{- $serviceAccount := "" -}}
  {{- if gt (len $context ) 3 }}
    {{- $serviceAccount = index $context 3 }}
  {{- end }}
  {{- $customRole := "" -}}
  {{- if gt (len $context ) 4 }}
    {{- $customRole = index $context 4 }}
  {{- end }}
  {{- $url := $vaultConf.url -}}
  {{- $skipVerify := $vaultConf.skipVerify -}}
  {{- $role := $customRole -}}
  {{- if $forceVault -}}
    {{- $role = default "vault" $vaultConf.role -}}
    {{- $serviceAccount =  default "vault" $vaultConf.serviceAccount -}}
  {{- else if and (not $customRole) $serviceAccount -}}
    {{- $role = $serviceAccount -}}
  {{- end -}}
authentication:
  path: {{ default $root.Values.spellbook.name $vaultConf.authPath }}
  role: {{ default (include "common.name" $root) $role }}
  serviceAccount:
    name: {{ default (include "common.name" $root) $serviceAccount }}
connection:
  address: {{ $url }}
  tLSConfig:
    skipVerify: {{ default "false" $skipVerify }}
{{- end -}}

{{- define "vault.secretPath" }}
{{- /* vault.secretPath generates Vault-specific secret paths.

This handles Vault KV v2 specific logic (like /data prefix) and database engine paths.

Parameters:
- $root: Chart root context (index . 0)
- $glyph: Glyph definition object (index . 1)
- $vaultConf: Vault config from lexicon (index . 2)
- $options: Optional dict (index . 3)

Options dict:
- engineType: string - "kv" (default) or "database"
- excludeName: bool - If true, don't append name (for create operations)

Vault-specific behavior:
- KV v2: Adds /data prefix to secretPath
- Database: No /data prefix (dynamic credentials)

Examples:
  {{- include "vault.secretPath" (list $root (dict "name" "api-key" "path" "book") $vaultConf (dict "engineType" "kv")) }}
  → kv/data/my-book/publics/api-key

  {{- include "vault.secretPath" (list $root (dict "name" "db-creds" "path" "chapter") $vaultConf (dict "engineType" "database")) }}
  → kv/my-book/prod/publics/db-creds (no /data prefix)
*/}}
  {{- $root := index . 0 }}
  {{- $glyph := index . 1 }}
  {{- $vaultConf := index . 2 }}
  {{- $options := dict }}
  {{- if gt (len .) 3 }}
    {{- $options = index . 3 }}
  {{- end }}

  {{- /* Vault-specific: engineType handling */ -}}
  {{- $engineType := default "kv" $options.engineType }}
  {{- $pathPrefix := "/data" }}

  {{- if eq $engineType "database" }}
    {{- $pathPrefix = "" }}
  {{- end }}

  {{- /* Build full basePath with Vault-specific prefix */ -}}
  {{- $basePath := printf "%s%s" $vaultConf.secretPath $pathPrefix }}

  {{- /* Call common.secretPath with prepared basePath */ -}}
  {{- include "common.secretPath" (list $root $glyph $basePath $options) }}
{{- end }}


{{- define "generateSecretPath" }}
{{- /* DEPRECATED: Use vault.secretPath instead.
Kept for backward compatibility with existing vault templates.
This wrapper will be removed in a future version.
*/}}
  {{- $root := index . 0 }}
  {{- $glyph := index . 1 }}
  {{- $vaultConf := index . 2 }}
  {{- $create := index . 3 }}
  {{- $engineType := "kv" }}
  {{- if gt (len .) 4 }}
    {{- $engineType = index . 4 }}
  {{- end }}

  {{- /* Build options dict */ -}}
  {{- $options := dict "engineType" $engineType }}
  {{- if ne $create "" }}
    {{- $options = merge $options (dict "excludeName" true) }}
  {{- end }}

  {{- /* Call new vault.secretPath */ -}}
  {{- include "vault.secretPath" (list $root $glyph $vaultConf $options) }}
{{- end }}
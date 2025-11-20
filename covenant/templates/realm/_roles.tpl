{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

Covenant Realm - Realm Roles
Generates realm roles from realm/roles/*.yaml
*/}}

{{- define "covenant.realm.roles" -}}
{{- $root := . -}}
{{- $covenantIndex := include "covenant.scanCovenantIndex" . | fromYaml -}}
{{- $finalRealm := $covenantIndex.realm -}}
{{- $realmRef := printf "realm-%s" (required "covenant realm.name is required" $finalRealm.name) -}}
{{- $keycloakGlyphs := dict -}}

{{/* Scan realm roles from realm/roles/*.yaml */}}
{{- $roles := include "covenant.scanRealmRoles" . | fromJson -}}

{{/* Generate realm roles */}}
{{- range $role := $roles }}
{{- $roleKey := printf "role-%s" $role.name -}}
{{- $_ := set $keycloakGlyphs $roleKey (dict
  "type" "realmRole"
  "realmRef" $realmRef
  "roleName" $role.name
  "description" (default "" $role.description)
  "composite" (default false $role.composite)
  "compositeRoles" $role.compositeRoles
  "attributes" $role.attributes
) }}
{{- end }}

{{/* Render keycloak glyphs */}}
{{- range $glyphName, $glyph := $keycloakGlyphs }}
  {{- $glyphWithName := merge $glyph (dict "name" $glyphName) }}
  {{- if eq $glyph.type "realmRole" }}
    {{- include "keycloak.realmRole" (list $root $glyphWithName) }}
  {{- end }}
{{- end }}

{{- end -}}

{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

Covenant Trinket Helper Templates
Identity and access management system
*/}}

{{/*
Common labels with kast-specific additions
*/}}
{{- define "covenant.labels" -}}
{{ include "common.labels" . }}
kast.io/component: covenant
kast.io/type: trinket
{{- end }}

{{/*
Selector labels
*/}}
{{- define "covenant.selectorLabels" -}}
{{ include "common.selectorLabels" . }}
{{- end }}

{{/*
Generate full member username (email or username)
Parameters: $member object
Returns: username string
*/}}
{{- define "covenant.memberUsername" -}}
{{- $member := . -}}
{{- default $member.email $member.username -}}
{{- end }}

{{/*
Generate full member name
Parameters: $member object
Returns: full name string
*/}}
{{- define "covenant.memberFullName" -}}
{{- $member := . -}}
{{- default (printf "%s %s" (default "" $member.firstName) (default "" $member.lastName)) $member.fullName -}}
{{- end }}

{{/*
Get Keycloak realm reference from lexicon
Parameters: $root context
Returns: realm name
*/}}
{{- define "covenant.getRealmRef" -}}
{{- $root := . -}}
{{- $realmName := "main" -}}
{{- if $root.Values.covenant.realm.name -}}
  {{- $realmName = $root.Values.covenant.realm.name -}}
{{- else if $root.Values.lexicon -}}
  {{- range $name, $item := $root.Values.lexicon -}}
    {{- if eq $item.type "keycloak-realm" -}}
      {{- if hasKey $item.labels "default" -}}
        {{- if eq (index $item.labels "default") "book" -}}
          {{- $realmName = $item.realmName -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- $realmName -}}
{{- end }}

{{/*
Merge member with chapel and area defaults
Parameters: (list $areaDefaults $chapelDefaults $member)
Returns: merged member object
*/}}
{{- define "covenant.mergeMemberDefaults" -}}
{{- $areaDefaults := index . 0 -}}
{{- $chapelDefaults := index . 1 -}}
{{- $member := index . 2 -}}
{{- $merged := deepCopy $member -}}

{{/* Merge roles: area < chapel < member */}}
{{- $roles := list -}}
{{- if $areaDefaults.defaultRoles -}}
  {{- $roles = concat $roles $areaDefaults.defaultRoles -}}
{{- end -}}
{{- if $chapelDefaults.defaultRoles -}}
  {{- $roles = concat $roles $chapelDefaults.defaultRoles -}}
{{- end -}}
{{- if $member.roles -}}
  {{- $roles = concat $roles $member.roles -}}
{{- end -}}
{{- if gt (len $roles) 0 -}}
  {{- $_ := set $merged "roles" ($roles | uniq) -}}
{{- end -}}

{{/* Merge integrations: area < chapel < member */}}
{{- if or $areaDefaults.integrations $chapelDefaults.integrations $member.integrations -}}
  {{- $integrations := deepCopy (default dict $areaDefaults.integrations) -}}
  {{- if $chapelDefaults.integrations -}}
    {{- $_ := mergeOverwrite $integrations (deepCopy $chapelDefaults.integrations) -}}
  {{- end -}}
  {{- if $member.integrations -}}
    {{- $_ := mergeOverwrite $integrations (deepCopy $member.integrations) -}}
  {{- end -}}
  {{- $_ := set $merged "integrations" $integrations -}}
{{- end -}}

{{/* Merge groups: area < chapel < member */}}
{{- $groups := list -}}
{{- if $areaDefaults.groups -}}
  {{- $groups = concat $groups $areaDefaults.groups -}}
{{- end -}}
{{- if $chapelDefaults.groups -}}
  {{- $groups = concat $groups $chapelDefaults.groups -}}
{{- end -}}
{{- if $member.groups -}}
  {{- $groups = concat $groups $member.groups -}}
{{- end -}}
{{- if gt (len $groups) 0 -}}
  {{- $_ := set $merged "groups" ($groups | uniq) -}}
{{- end -}}

{{- $merged | toJson -}}
{{- end }}

{{/*
Generate Keycloak group name from area/chapel
Parameters: (list $areaName $chapelName)
Returns: group name
*/}}
{{- define "covenant.groupName" -}}
{{- $areaName := index . 0 -}}
{{- $chapelName := index . 1 -}}
{{- if $chapelName -}}
  {{- printf "%s-%s" $areaName $chapelName -}}
{{- else -}}
  {{- $areaName -}}
{{- end -}}
{{- end }}

{{/*
Generate Keycloak user name (sanitized)
Parameters: $memberName string
Returns: sanitized username
*/}}
{{- define "covenant.sanitizeUsername" -}}
{{- $memberName := . -}}
{{- $memberName | replace "." "-" | lower | trunc 63 | trimSuffix "-" -}}
{{- end }}

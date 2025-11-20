{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

Covenant Scanning Helpers
Scans bookrack structure for covenant resources
*/}}

{{- define "covenant.scanCovenantIndex" -}}
{{- $bookPath := default .Release.Name .Values.name -}}
{{- $covenantIndexPath := printf "bookrack/%s/covenant/index.yaml" $bookPath -}}
{{- if not (.Files.Glob $covenantIndexPath) -}}
  {{- $covenantIndexPath = printf "bookrack/%s/index.yaml" $bookPath -}}
  {{- if not (.Files.Glob $covenantIndexPath) -}}
    {{- fail (printf "covenant/index.yaml or index.yaml not found in bookrack/%s" $bookPath) -}}
  {{- end -}}
{{- end -}}
{{- .Files.Get $covenantIndexPath -}}
{{- end -}}

{{- define "covenant.scanRealmRoles" -}}
{{- $bookPath := default .Release.Name .Values.name -}}
{{- $roles := list -}}
{{- $rolesGlob := printf "bookrack/%s/realm/roles/*.yaml" $bookPath -}}
{{- if .Files.Glob $rolesGlob -}}
  {{- range $path, $_ := .Files.Glob $rolesGlob -}}
    {{- $role := $.Files.Get $path | fromYaml -}}
    {{- $roles = append $roles $role -}}
  {{- end -}}
{{- end -}}
{{- $roles | toJson -}}
{{- end -}}

{{- define "covenant.scanRealmIntegrations" -}}
{{- $bookPath := default .Release.Name .Values.name -}}
{{- $integrations := dict -}}
{{- $integrationsGlob := printf "bookrack/%s/realm/integrations/*.yaml" $bookPath -}}
{{- if not (.Files.Glob $integrationsGlob) -}}
  {{- $integrationsGlob = printf "bookrack/%s/conventions/integrations/*.yaml" $bookPath -}}
{{- end -}}
{{- range $path, $_ := .Files.Glob $integrationsGlob -}}
  {{- $fileName := base $path | trimSuffix ".yaml" | trimSuffix ".yml" -}}
  {{- $integration := $.Files.Get $path | fromYaml -}}
  {{- if $integration.enabled -}}
    {{- $_ := set $integrations $fileName $integration -}}
  {{- end -}}
{{- end -}}
{{- $integrations | toJson -}}
{{- end -}}

{{- define "covenant.scanRealmClientScopes" -}}
{{- $bookPath := default .Release.Name .Values.name -}}
{{- $scopes := dict -}}
{{- $scopesGlob := printf "bookrack/%s/realm/client-scopes/*.yaml" $bookPath -}}
{{- if not (.Files.Glob $scopesGlob) -}}
  {{- $scopesGlob = printf "bookrack/%s/conventions/client-scopes/*.yaml" $bookPath -}}
{{- end -}}
{{- range $path, $_ := .Files.Glob $scopesGlob -}}
  {{- $fileName := base $path | trimSuffix ".yaml" | trimSuffix ".yml" -}}
  {{- $scope := $.Files.Get $path | fromYaml -}}
  {{- $_ := set $scopes $fileName $scope -}}
{{- end -}}
{{- $scopes | toJson -}}
{{- end -}}

{{- define "covenant.scanRealmIDPs" -}}
{{- $bookPath := default .Release.Name .Values.name -}}
{{- $idps := dict -}}
{{- $idpsGlob := printf "bookrack/%s/realm/idps/*.yaml" $bookPath -}}
{{- if not (.Files.Glob $idpsGlob) -}}
  {{- $idpsGlob = printf "bookrack/%s/conventions/identity-providers/*.yaml" $bookPath -}}
{{- end -}}
{{- range $path, $_ := .Files.Glob $idpsGlob -}}
  {{- $fileName := base $path | trimSuffix ".yaml" | trimSuffix ".yml" -}}
  {{- $idp := $.Files.Get $path | fromYaml -}}
  {{- if $idp.enabled -}}
    {{- $_ := set $idps $fileName $idp -}}
  {{- end -}}
{{- end -}}
{{- $idps | toJson -}}
{{- end -}}

{{- define "covenant.scanRealmAuthFlows" -}}
{{- $bookPath := default .Release.Name .Values.name -}}
{{- $flows := dict -}}
{{- $flowsGlob := printf "bookrack/%s/realm/auth-flows/*.yaml" $bookPath -}}
{{- range $path, $_ := .Files.Glob $flowsGlob -}}
  {{- $fileName := base $path | trimSuffix ".yaml" | trimSuffix ".yml" -}}
  {{- $flow := $.Files.Get $path | fromYaml -}}
  {{- $_ := set $flows $fileName $flow -}}
{{- end -}}
{{- $flows | toJson -}}
{{- end -}}

{{- define "covenant.scanChapterIndex" -}}
{{- $root := index . 0 -}}
{{- $chapterName := index . 1 -}}
{{- $bookPath := default $root.Release.Name $root.Values.name -}}
{{- $chapterIndexPath := printf "bookrack/%s/covenant/%s/index.yaml" $bookPath $chapterName -}}
{{- if not ($root.Files.Glob $chapterIndexPath) -}}
  {{- $chapterIndexPath = printf "bookrack/%s/%s/index.yaml" $bookPath $chapterName -}}
  {{- if not ($root.Files.Glob $chapterIndexPath) -}}
    {{- fail (printf "covenant/%s/index.yaml or %s/index.yaml not found in bookrack/%s" $chapterName $chapterName $bookPath) -}}
  {{- end -}}
{{- end -}}
{{- $root.Files.Get $chapterIndexPath -}}
{{- end -}}

{{- define "covenant.scanChapterMembers" -}}
{{- $root := index . 0 -}}
{{- $chapterName := index . 1 -}}
{{- $bookPath := default $root.Release.Name $root.Values.name -}}
{{- $members := dict -}}
{{- $membersGlob := printf "bookrack/%s/covenant/%s/*/*.yaml" $bookPath $chapterName -}}
{{- if not ($root.Files.Glob $membersGlob) -}}
  {{- $membersGlob = printf "bookrack/%s/%s/*/*.yaml" $bookPath $chapterName -}}
{{- end -}}
{{- range $path, $_ := $root.Files.Glob $membersGlob -}}
  {{- $chapelName := base (dir $path) -}}
  {{- $fileName := base $path | trimSuffix ".yaml" | trimSuffix ".yml" -}}
  {{- $memberKey := printf "%s/%s" $chapelName $fileName -}}
  {{- $memberData := $root.Files.Get $path | fromYaml -}}
  {{- $memberWithContext := merge $memberData (dict "chapel" $chapelName) -}}
  {{- $_ := set $members $memberKey $memberWithContext -}}
{{- end -}}
{{- $members | toJson -}}
{{- end -}}

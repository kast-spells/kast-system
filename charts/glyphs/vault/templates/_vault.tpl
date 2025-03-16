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
  {{- $url := $vaultConf.url -}}
  {{- $skipVerify := $vaultConf.skipVerify -}}
  {{- $path := $vaultConf.path -}}
  {{- $role := "" -}}
  {{- if $forceVault -}}
    {{- $role = $vaultConf.role -}}
    {{- $serviceAccount = $vaultConf.serviceAccount -}}
  {{- end -}}
authentication: 
  path: {{ default $root.Values.spellbook.name $vaultConf.path }}
  role: {{ default (include "common.name" $root) $role }}
  serviceAccount:
    name: {{ default (include "common.name" $root) $serviceAccount }}
connection:
  address: {{ $url }}
  tLSConfig:
    skipVerify: {{ default "false" $skipVerify }}
{{- end -}}


{{- define "generateSecretPath" }}
  {{- $root := index . 0 }}
  {{- $secretName := index . 1 }}
  {{- $secret := index . 2 }}
  {{- $internalPath := default "publics" $secret.source.private }}
  {{- $path := default "" $secret.source.path }}
  {{- if eq $path "spellbook" }}
    {{- printf "secrets/data/%s/%s/%s" $root.Values.spellbook.name $internalPath $secretName }}
  {{- else if eq $path "chapter" }}
    {{- printf "secrets/data/%s/%s/%s/%s" $root.Values.spellbook.name $root.Values.chapter.name $internalPath $secretName  }}
  {{- else if hasPrefix "/" $path }}
    {{- printf "secrets/data%s" $path }}
  {{- else }}
    {{- printf "secrets/data/%s/%s/%s/%s/%s" 
          $root.Values.spellbook.name 
          $root.Values.chapter.name 
          $root.Release.Namespace
          $internalPath 
          $secretName
     }}
  {{- end }}
{{- end }}
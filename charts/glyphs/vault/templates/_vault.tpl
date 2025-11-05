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


{{- define "generateSecretPath" }}
  {{- $root := index . 0 }}
  {{- $glyph := index . 1 }}
  {{- $vaultConf := index . 2 }}
  {{- $create := index . 3 }}
  {{- $engineType := "kv" }}
  {{- if gt (len .) 4 }}
    {{- $engineType = index . 4 }}
  {{- end }}
  {{- $internalPath := default "publics" $glyph.private }}
  {{- $path := default "" $glyph.path }}
  {{- $name := $glyph.name}}
  {{- if $create }}
  {{- $name = "" }}
  {{- end }}
  {{- $dataPrefix := "/data" }}
  {{- if eq $engineType "database" }}
    {{- $dataPrefix = "" }}
  {{- end }}
  {{- if eq $path "book" }}
    {{- printf "%s%s/%s/%s/%s"
              $vaultConf.secretPath
              $dataPrefix
              $root.Values.spellbook.name
              $internalPath
              $name }}
  {{- else if eq $path "chapter" }}
    {{- printf "%s%s/%s/%s/%s/%s"
                $vaultConf.secretPath
                $dataPrefix
                $root.Values.spellbook.name
                $root.Values.chapter.name
                $internalPath
                $name  }}
  {{- else if hasPrefix "/" $path }}
    {{- if hasSuffix "/" $path }}
      {{- printf "%s%s%s%s"
                  $vaultConf.secretPath
                  $dataPrefix
                  $path
                  $name }}
    {{- else }}
      {{- printf "%s%s%s"
                  $vaultConf.secretPath
                  $dataPrefix
                  $path }}
    {{- end }}
  {{- else }}
    {{- printf "%s%s/%s/%s/%s/%s/%s"
          $vaultConf.secretPath
          $dataPrefix
          $root.Values.spellbook.name
          $root.Values.chapter.name
          $root.Release.Namespace
          $internalPath
          $name  }}
  {{- end }}
{{- end }}
{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
TODO hardcoded all of it
*/}}

{{- define "vault.passwordPolicy" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}
{{- $vaultServer := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.selector) "vault" $root.Values.chapter.name ) | fromJson) "results" }}
{{- range $vaultConf := $vaultServer }}
---
apiVersion: redhatcop.redhat.io/v1alpha1
kind: PasswordPolicy
metadata:
  name: simple-password-policy
  labels:
    {{- include "common.all.labels" $root | nindent 4 }}
    {{- with $glyphDefinition.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  annotations:
    {{- include "common.annotations" $root | nindent 4 }}
    argocd.argoproj.io/sync-wave: "5"
    {{- with $glyphDefinition.annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  {{- include "vault.connect" (list $root $vaultConf "") | nindent 2 }}
  passwordPolicy: |
    length = 36
    rule "charset" {
      charset = "abcdefghijklmnopqrstuvwxyz"
      min-chars = 3
    }
    rule "charset" {
      charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
      min-chars = 3
    }
    rule "charset" {
      charset = "0123456789"
      min-chars = 3
    }
    rule "charset" {
      charset = "#%~^_-+=.,:?"
      min-chars = 3
    }
{{- end -}}
{{- end -}}
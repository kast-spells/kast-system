{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

vault.defaultPasswordPolicy creates default password policies for HashiCorp Vault.
Follows standard glyph parameter pattern: (list $root $glyphDefinition).

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: Password policy configuration object (index . 1)

Example minimal glyph definition:
  vault:
    - type: defaultPasswordPolicy
      name: default

*/}}

{{- define "vault.defaultPasswordPolicy" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}
{{- $vaultServer := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.selector) "vault" $root.Values.chapter.name ) | fromJson) "results" }}
{{- range $vaultConf := $vaultServer }}
---
apiVersion: redhatcop.redhat.io/v1alpha1
kind: PasswordPolicy
metadata:
  name: {{ default "default" $glyphDefinition.name }}
  namespace: {{ $vaultConf.namespace }}
spec:
  {{- include "vault.connect" (list $root $vaultConf "vault" $glyphDefinition.serviceAccount) | nindent 2 }}
  passwordPolicy: |
    length = {{ default "20" $glyphDefinition.length }}
    rule "charset" {
      charset = "abcdefghijklmnopqrstuvwxyz"
      min-chars = {{ default "1" $glyphDefinition.minLowercase }}
    }
    rule "charset" {
      charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
      min-chars = {{ default "1" $glyphDefinition.minUppercase }}
    }
    rule "charset" {
      charset = "0123456789"
      min-chars = {{ default "1" $glyphDefinition.minNumbers }}
    }
    rule "charset" {
      charset = "!@#$%^&*"
      min-chars = {{ default "1" $glyphDefinition.minSymbols }}
    }
{{- end }}
{{- end }}
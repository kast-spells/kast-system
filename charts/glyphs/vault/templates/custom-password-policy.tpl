{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

vault.customPasswordPolicy creates fully customizable password policies for HashiCorp Vault.
Allows complete control over the password policy definition.

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: Password policy configuration object (index . 1)
  - name: Policy name (required)
  - policy: Complete policy definition as string or map (required)
  - selector: Optional vault server selector

Example glyph definition:
  vault:
    - type: customPasswordPolicy
      name: complex-requirements
      policy: |
        length = 30
        rule "charset" {
          charset = "abcdefghijklmnopqrstuvwxyz"
          min-chars = 5
        }
        rule "charset" {
          charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
          min-chars = 5
        }
        rule "charset" {
          charset = "0123456789"
          min-chars = 5
        }
        rule "charset" {
          charset = "!@#$%^&*()-_=+[]{}|;:,.<>?"
          min-chars = 5
        }
        rule "allowed" {
          charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+[]{}|;:,.<>?"
        }

    - type: customPasswordPolicy
      name: pronounceable
      policy:
        length: 20
        rules:
          - type: generate
            generator: pronounceable

*/}}

{{- define "vault.customPasswordPolicy" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}
{{- $vaultServer := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.selector) "vault" $root.Values.chapter.name ) | fromJson) "results" }}
{{- range $vaultConf := $vaultServer }}
---
apiVersion: redhatcop.redhat.io/v1alpha1
kind: PasswordPolicy
metadata:
  name: {{ required "Password policy name is required" $glyphDefinition.name }}
  namespace: {{ $vaultConf.namespace }}
  {{- if $glyphDefinition.annotations }}
  annotations:
    {{- toYaml $glyphDefinition.annotations | nindent 4 }}
  {{- end }}
spec:
  {{- include "vault.connect" (list $root $vaultConf "vault" $glyphDefinition.serviceAccount) | nindent 2 }}
  passwordPolicy: |
{{- if kindIs "string" $glyphDefinition.policy }}
    {{- $glyphDefinition.policy | nindent 4 }}
{{- else if kindIs "map" $glyphDefinition.policy }}
    {{/* Convert map to HCL format */}}
    length = {{ required "policy.length is required" $glyphDefinition.policy.length }}
    {{- range $glyphDefinition.policy.rules }}
    rule "{{ .type }}" {
      {{- if .charset }}
      charset = "{{ .charset }}"
      {{- end }}
      {{- if .minChars }}
      min-chars = {{ .minChars }}
      {{- end }}
      {{- if .generator }}
      generator = "{{ .generator }}"
      {{- end }}
    }
    {{- end }}
{{- else }}
    {{- fail "policy must be either a string or a map" }}
{{- end }}
{{- end }}
{{- end }}
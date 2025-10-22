{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

vault.prolicy creates Vault Policy and KubernetesAuthEngineRole for service authentication.

Parameters:
- $root: Chart root context (index . 0)
- $glyph: Policy configuration (index . 1)
  - nameOverride: Policy name (default: common.name)
  - serviceAccount: ServiceAccount to bind (default: common.name)
  - bookPublicsWrite: Enable write to book/publics path (default: false)
  - chapterPublicsWrite: Enable write to chapter/publics path (default: false)
  - extraPolicy: Additional policy paths (array)

Generated Resources:
- Policy: Vault policy with namespace-scoped permissions
- KubernetesAuthEngineRole: K8s auth binding

Default Permissions:
- Full access to: {book}/{chapter}/{namespace}/*
- Read/List: {book}/publics/*, {book}/{chapter}/publics/*, {book}/pipelines/*
- Write enabled with flags: bookPublicsWrite, chapterPublicsWrite

Usage:
  vault:
    - type: prolicy
      name: my-policy
      serviceAccount: my-app
      bookPublicsWrite: true
      chapterPublicsWrite: true
*/}}

{{- define "vault.prolicy" -}}
{{- $root := index . 0 -}}
{{- $glyph := index . 1 }}
{{- $vaultServer := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyph.selector) "vault" $root.Values.chapter.name ) | fromJson) "results" }}
{{- range $vaultConf := $vaultServer }}

{{/* Determine capabilities for publics paths based on flags */}}
{{- $bookPublicsCapabilities := list "read" "list" }}
{{- $chapterPublicsCapabilities := list "read" "list" }}
{{- if $glyph.bookPublicsWrite }}
  {{- $bookPublicsCapabilities = list "create" "read" "update" "delete" "list" }}
{{- end }}
{{- if $glyph.chapterPublicsWrite }}
  {{- $chapterPublicsCapabilities = list "create" "read" "update" "delete" "list" }}
{{- end }}

---
apiVersion: redhatcop.redhat.io/v1alpha1
kind: Policy
metadata:
  name:  {{ default ( include "common.name" $root ) $glyph.nameOverride }}
  namespace: {{ default "vault" $vaultConf.namespace }}
spec:
{{- include "vault.connect" (list $root $vaultConf  "True")  |nindent 2}}
  policy: |
    {{/* Namespace-scoped paths - Full CRUD access */}}
    path "{{ $vaultConf.secretPath }}/data/{{ $root.Values.spellbook.name }}/{{ $root.Values.chapter.name }}/{{ default $root.Release.Namespace $glyph.nameOverride }}/*" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }
    path "{{ $vaultConf.secretPath }}/metadata/{{ $root.Values.spellbook.name }}/{{ $root.Values.chapter.name }}/{{ default $root.Release.Namespace $glyph.nameOverride }}/*" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }

    {{/* Chapter publics - Shared across chapter (controlled by flag) */}}
    path "{{ $vaultConf.secretPath }}/data/{{ $root.Values.spellbook.name }}/{{ $root.Values.chapter.name }}/publics/*" {
      capabilities = {{ $chapterPublicsCapabilities | toJson }}
    }
    path "{{ $vaultConf.secretPath }}/metadata/{{ $root.Values.spellbook.name }}/{{ $root.Values.chapter.name }}/publics/*" {
      capabilities = {{ $chapterPublicsCapabilities | toJson }}
    }

    {{/* Book publics - Shared across book (controlled by flag) */}}
    path "{{ $vaultConf.secretPath }}/data/{{ $root.Values.spellbook.name }}/publics/*" {
      capabilities = {{ $bookPublicsCapabilities | toJson }}
    }
    path "{{ $vaultConf.secretPath }}/metadata/{{ $root.Values.spellbook.name }}/publics/*" {
      capabilities = {{ $bookPublicsCapabilities | toJson }}
    }

    {{/* Book pipelines - Read-only for CI/CD */}}
    path "{{ $vaultConf.secretPath }}/data/{{ $root.Values.spellbook.name }}/pipelines/*" {
      capabilities = ["read", "list"]
    }
    path "{{ $vaultConf.secretPath }}/metadata/{{ $root.Values.spellbook.name }}/pipelines/*" {
      capabilities = ["read", "list"]
    }

    {{/* Password policies - Read-only for all */}}
    path "sys/policies/password/*" {
      capabilities = ["read", "list"]
    }

    {{/* Extra policies from spellbook */}}
    {{- if ($root.Values.spellbook.prolicy).extraPolicy }}
    {{- range $root.Values.spellbook.prolicy.extraPolicy }}
    path "{{ .path }}" {
      capabilities = {{ .capabilities | toJson }}
    }
    {{- end }}
    {{- end }}

    {{/* Extra policies from chapter */}}
    {{- if ($root.Values.chapter.prolicy).extraPolicy }}
    {{- range $root.Values.chapter.prolicy.extraPolicy }}
    path "{{ .path }}" {
      capabilities = {{ .capabilities | toJson }}
    }
    {{- end }}
    {{- end }}

    {{/* Extra policies from vault lexicon */}}
    {{- if $vaultConf.extraPolicy }}
    {{- range $vaultConf.extraPolicy }}
    path "{{ .path }}" {
      capabilities = {{ .capabilities | toJson }}
    }
    {{- end }}
    {{- end }}

    {{/* Extra policies from glyph definition */}}
    {{- if $glyph.extraPolicy }}
    {{- range $glyph.extraPolicy }}
    path "{{ .path }}" {
      capabilities = {{ .capabilities | toJson }}
    }
    {{- end }}
    {{- end }}

---
apiVersion: redhatcop.redhat.io/v1alpha1
kind: KubernetesAuthEngineRole
metadata:
  name: {{ default ( include "common.name" $root ) $glyph.nameOverride }}
  namespace: {{ default "vault" $vaultConf.namespace }}
spec:
  {{- include "vault.connect" (list $root $vaultConf  "True") |nindent 2 }}
  path: {{ default $root.Values.spellbook.name $vaultConf.path }}
  policies:
    - {{ default ( include "common.name" $root ) $glyph.nameOverride }}
  targetServiceAccounts:
    - {{  default (include "common.name" $root) $glyph.serviceAccount }}
  targetNamespaces:
    targetNamespaces:
      - {{ $root.Release.Namespace }}
{{- end }}
{{- end }}

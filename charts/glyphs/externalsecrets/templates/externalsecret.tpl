{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2025 laaledesiempre@disroot.org
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "vault.external-secret-vault" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
{{- $vaultServer := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.selector) "vault" $root.Values.chapter.name ) | fromJson) "results" }}
---
apiVersion: external-secrets.io/v1alpha1
kind: ExternalSecret
metadata:
  name: {{ default (include "common.name" $root ) $glyphDefinition.name }}
spec:
  refreshInterval: {{ default 30m $glyphDefinition.refreshInterval}}
  secretStoreRef: # lexicon construct
    name: core-communications # from lexicon
    kind: ClusterSecretStore # default
  target:
    name: {{ default (include "common.name" $root ) $glyphDefinition.name }}
  dataFrom: #lexicon construct
    - key: {{ include "generateSecretPath" ( list $root $glyphDefinition $vaultServer "" ) }}

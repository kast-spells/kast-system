{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2025 laaledesiempre@disroot.org
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "vault.cluster-secret-store-vault" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: external-secrets.io/v1alpha1
kind: ClusterSecretStore
metadata:
  name: {{ default (include "common.name" $root ) $glyphDefinition.name }}
spec:
  provider:
    vault:
      auth:
        tokenSecretRef:
          {{ $tokenRefData:= split "/" $glyphDefinition.tokenSecretRef }}
          key: token
          name: {{ tokenRefData._0 }}
          namespace: {{ tokenRefData._1 }}
      path: {{ $glyphDefinition.path }}
      server: {{ default "vault.vault" $glyphDefinition.server }}
      version: v2

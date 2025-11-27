{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

vault.serverRbac creates Vault server RBAC resources including ServiceAccount, Role, ClusterRole and bindings.
Follows standard glyph parameter pattern: (list $root $glyphDefinition).

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: Server RBAC configuration object (index . 1)

Example minimal glyph definition:
  vault:
    - type: serverRbac
      name: vault

*/}}

{{- define "vault.serverRbac" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}
{{- $vaultServer := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.selector) "vault" $root.Values.chapter.name ) | fromJson) "results" }}
{{- range $vaultConf := $vaultServer }}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ default "vault" $glyphDefinition.name }}
  namespace: {{ $vaultConf.namespace }}
  labels:
    {{- include "common.all.labels" $root | nindent 4 }}
    {{- with $glyphDefinition.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $glyphDefinition.annotations }}
  annotations:
    {{- include "common.annotations" $root | nindent 4 }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ default "vault" $glyphDefinition.name }}
  namespace: {{ $vaultConf.namespace }}
  labels:
    {{- include "common.all.labels" $root | nindent 4 }}
    {{- with $glyphDefinition.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $glyphDefinition.annotations }}
  annotations:
    {{- include "common.annotations" $root | nindent 4 }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "watch", "list", "create", "update", "delete"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list", "patch"]
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: {{ default "vault" $glyphDefinition.name }}-tokenreview
rules:
- apiGroups: ["authentication.k8s.io"]
  resources: ["tokenreviews"]
  verbs: ["create"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: {{ default "vault" $glyphDefinition.name }}-tokenreview
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: {{ default "vault" $glyphDefinition.name }}-tokenreview
subjects:
- kind: ServiceAccount
  name: {{ default "vault" $glyphDefinition.name }}
  namespace: {{ $vaultConf.namespace }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ default "vault" $glyphDefinition.name }}
  namespace: {{ $vaultConf.namespace }}
subjects:
- kind: ServiceAccount
  name: {{ default "vault" $glyphDefinition.name }}
  namespace: {{ $vaultConf.namespace }}
roleRef:
  kind: Role
  name: {{ default "vault" $glyphDefinition.name }}
  apiGroup: rbac.authorization.k8s.io
{{- end }}
{{- end }}
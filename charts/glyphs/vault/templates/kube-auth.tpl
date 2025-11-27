{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

vault.kubeAuth creates Kubernetes authentication configuration for HashiCorp Vault.
Follows standard glyph parameter pattern: (list $root $glyphDefinition).

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: Kubernetes auth configuration object (index . 1)

Example minimal glyph definition:
  vault:
    - type: kubeAuth
      name: cluster-dev
      clusterSelector:
        name: dev-cluster
      createRemoteRBAC: true

*/}}

{{- define "vault.kubeAuth" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}
{{- $vaultServer := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.selector) "vault" $root.Values.chapter.name ) | fromJson) "results" }}
{{- $clusterData := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.clusterSelector) "k8s" $root.Values.chapter.name ) | fromJson) "results" }}
{{- range $vaultConf := $vaultServer }}
{{- range $cluster := $clusterData }}
{{- if $glyphDefinition.createRemoteRBAC }}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: vault-token-reviewer
  namespace: vault
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: vault-token-reviewer
rules:
- apiGroups: ["authentication.k8s.io"]
  resources: ["tokenreviews"]
  verbs: ["create"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: vault-token-reviewer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: vault-token-reviewer
subjects:
- kind: ServiceAccount
  name: vault-token-reviewer
  namespace: vault
{{- end }}
---
apiVersion: redhatcop.redhat.io/v1alpha1
kind: AuthEngineMount
metadata:
  name: {{ $glyphDefinition.name }}
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
spec:
  {{- include "vault.connect" (list $root $vaultConf "vault" $glyphDefinition.serviceAccount) | nindent 2 }}
  type: kubernetes
---
apiVersion: redhatcop.redhat.io/v1alpha1
kind: KubernetesAuthEngineConfig
metadata:
  name: {{ $glyphDefinition.name }}
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
spec:
  {{- include "vault.connect" (list $root $vaultConf "vault" $glyphDefinition.serviceAccount) | nindent 2 }}
  tokenReviewerServiceAccount:
    name: vault-token-reviewer
  kubernetesHost: {{ $cluster.apiServer }}
  kubernetesCACert: {{ $cluster.caCert | nindent 4 }}
---
apiVersion: redhatcop.redhat.io/v1alpha1
kind: KubernetesAuthEngineRole
metadata:
  name: {{ $glyphDefinition.name }}
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
spec:
  {{- include "vault.connect" (list $root $vaultConf "vault" $glyphDefinition.serviceAccount) | nindent 2 }}
  path: {{ $glyphDefinition.name }}
  policies:
    - vault
  targetServiceAccounts:
    - vault
  targetNamespaces:
    targetNamespaces:
      - vault
{{- end }}
{{- end }}
{{- end }}
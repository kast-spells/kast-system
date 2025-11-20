{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

Covenant Post-Provisioning - RBAC
Generates ServiceAccount, Role, and RoleBinding for post-provisioning jobs
*/}}

{{- define "covenant.postProvisioning.rbac" -}}
{{- $root := . -}}
{{- $covenant := .Values.covenant -}}
{{- $bookPath := default .Release.Name .Values.name -}}
{{- if $covenant.chapterFilter }}
  {{- $bookPath = trimSuffix (printf "-%s" $covenant.chapterFilter) $bookPath -}}
{{- end }}
{{- $postProvisionSA := printf "%s-post-provision" $bookPath -}}

{{/* Get chapter index to check for post-provisioning */}}
{{- $chapterFilter := $covenant.chapterFilter -}}
{{- $chapterIndex := include "covenant.scanChapterIndex" (list . $chapterFilter) | fromYaml -}}
{{- $hasPostProv := or $chapterIndex.chapterPostProvisioning $chapterIndex.memberPostProvisioning -}}

{{- if $hasPostProv }}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ $postProvisionSA }}
  namespace: {{ $root.Release.Namespace }}
  labels:
    {{- include "common.labels" $root | nindent 4}}
    covenant.kast.io/type: post-provisioning
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ $postProvisionSA }}
  namespace: {{ $root.Release.Namespace }}
  labels:
    {{- include "common.labels" $root | nindent 4}}
    covenant.kast.io/type: post-provisioning
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["create", "update", "patch", "get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ $postProvisionSA }}
  namespace: {{ $root.Release.Namespace }}
  labels:
    {{- include "common.labels" $root | nindent 4}}
    covenant.kast.io/type: post-provisioning
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: {{ $postProvisionSA }}
subjects:
  - kind: ServiceAccount
    name: {{ $postProvisionSA }}
    namespace: {{ $root.Release.Namespace }}
{{- end }}

{{- end -}}

{{- define "covenant.postProvisioning.rbac" -}}
{{- $covenant := .Values.covenant -}}
{{- $bookPath := default .Release.Name .Values.name -}}
{{- if $covenant.chapterFilter }}
  {{- $bookPath = trimSuffix (printf "-%s" $covenant.chapterFilter) $bookPath -}}
{{- end }}
{{- $chapterFilter := $covenant.chapterFilter -}}
{{- $postProvisionSA := printf "%s-post-provision" $bookPath -}}
{{- $chapterIndex := include "covenant.scanChapterIndex" (list . $chapterFilter) | fromYaml -}}
{{- $hasPostProv := or $chapterIndex.chapterPostProvisioning $chapterIndex.memberPostProvisioning -}}
{{- if $hasPostProv }}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ $postProvisionSA }}
  namespace: {{ .Release.Namespace }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ $postProvisionSA }}
  namespace: {{ .Release.Namespace }}
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["create", "update", "patch", "get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ $postProvisionSA }}
  namespace: {{ .Release.Namespace }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: {{ $postProvisionSA }}
subjects:
  - kind: ServiceAccount
    name: {{ $postProvisionSA }}
    namespace: {{ .Release.Namespace }}
{{- end }}
{{- end -}}

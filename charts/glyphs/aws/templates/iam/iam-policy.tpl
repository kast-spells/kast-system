{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "aws.iam-policy" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: iam.services.k8s.aws/v1alpha1
kind: Policy
metadata:
  name: {{ default (include "common.name" $root) $glyphDefinition.name }}
  namespace: {{ default $root.Release.Namespace  $glyphDefinition.namespace }}
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
  name: {{ default (include "common.name" $root) $glyphDefinition.name }}
  {{- with $glyphDefinition.path }}
  path: {{ . }}
  {{- end }}
  description: "{{ default (include "common.name" $root) $glyphDefinition.description }}"
  policyDocument: |
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "{{ $glyphDefinition.resources.effect | title }}",
          "Action": {{ $glyphDefinition.resources.actions | toJson | toString }},
          "Resource": "{{ $glyphDefinition.resources.arn }}"
        }
      ]
    }
  {{- with $glyphDefinition.tags }}
  tags:
    {{- range . }}
    - key: {{ .key }}
      value: {{ .value }}
    {{- end }}
  {{- end }}
{{- end }}
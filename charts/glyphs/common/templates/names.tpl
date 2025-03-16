{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

name defines a template for the name of the chart. It should be used for the `app` label. 
This is common practice in many Kubernetes manifests, and is not Helm-specific.

The prevailing wisdom is that names should only contain a-z, 0-9 plus dot (.) and dash (-), and should
not exceed 63 characters.

Parameters:

- .Values.nameOverride: Replaces the computed name with this given name
- .Values.namePrefix: Prefix
- .Values.global.namePrefix: Global prefix
- .Values.nameSuffix: Suffix
- .Values.global.nameSuffix: Global suffix

The applied order is: "global prefix + prefix + name + suffix + global suffix"

Usage: 'name: "{{- template "common.name" . -}}"'
*/ -}}
{{- define "common.name"}}
  {{- $base := default .Release.Name .Values.name -}}
  {{- $pre := default "" .Values.namePrefix -}}
  {{- $suf := default "" .Values.nameSuffix -}}
  {{- $name := print $pre $base $suf -}}
  {{- $name | lower | trunc 54 | trimSuffix "-" -}}
{{- end -}}


{{- define "common.serviceAccountName" -}}
{{ print ( default (include "common.name" . ) .Values.serviceAccount.name ) }}
{{- end -}}

{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

Template Resolution for Cluster-Wide WorkflowTemplates
Handles resolution and parameter injection for cluster-wide workflow templates
*/}}

{{/*
Lookup cluster-wide workflow template from lexicon
Parameters: (list $root $templateName)
Returns: Template definition as JSON or empty string if not found
*/}}
{{- define "tarot.lookupClusterTemplate" -}}
{{- $root := index . 0 -}}
{{- $templateName := index . 1 -}}
{{- $found := "" -}}

{{/* Search in lexicon for workflow templates */}}
{{- if $root.Values.lexicon -}}
  {{- range $root.Values.lexicon -}}
    {{- if and (eq .name $templateName) (eq .type "workflow-template") -}}
      {{- $found = . | toJson -}}
      {{- break -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- $found -}}
{{- end -}}

{{/*
Generate workflow parameters from tarot parameters
Parameters: (list $root $tarotParameters)
Returns: Workflow arguments parameters array
*/}}
{{- define "tarot.generateWorkflowParameters" -}}
{{- $root := index . 0 -}}
{{- $tarotParameters := index . 1 | default dict -}}

{{- $parameters := list -}}
{{- range $paramName, $paramValue := $tarotParameters -}}
  {{- $resolvedValue := include "tarot.resolveValue" (list $root $paramValue) -}}
  {{- $parameter := dict "name" $paramName "value" $resolvedValue -}}
  {{- $parameters = append $parameters $parameter -}}
{{- end -}}

{{- $parameters | toYaml -}}
{{- end -}}

{{/*
Generate cluster template workflow reference
Parameters: (list $root $templateDef)
Returns: WorkflowTemplateRef definition
*/}}
{{- define "tarot.generateTemplateRef" -}}
{{- $root := index . 0 -}}
{{- $templateDef := index . 1 -}}

workflowTemplateRef:
  name: {{ $templateDef.name | quote }}
  {{- if $templateDef.clusterScope }}
  clusterScope: true
  {{- end }}
{{- end -}}

{{/*
Validate template parameters against tarot parameters
Parameters: (list $templateDef $tarotParameters)
Returns: Validation result (empty string if valid, error message if invalid)
*/}}
{{- define "tarot.validateTemplateParameters" -}}
{{- $templateDef := index . 0 -}}
{{- $tarotParameters := index . 1 | default dict -}}

{{- $errors := list -}}

{{/* Check if template has parameter requirements */}}
{{- if $templateDef.template -}}
  {{- if $templateDef.template.spec -}}
    {{- if $templateDef.template.spec.arguments -}}
      {{- if $templateDef.template.spec.arguments.parameters -}}
        {{- range $templateDef.template.spec.arguments.parameters -}}
          {{- if and (not .value) (not (hasKey $tarotParameters .name)) -}}
            {{- $errors = append $errors (printf "Required parameter '%s' not provided" .name) -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/* Return validation errors */}}
{{- if $errors -}}
  {{- join "; " $errors -}}
{{- end -}}
{{- end -}}

{{/*
Generate workflow from cluster template
Parameters: (list $root $templateDef)
Returns: Complete workflow definition using template reference
*/}}
{{- define "tarot.generateWorkflowFromTemplate" -}}
{{- $root := index . 0 -}}
{{- $templateDef := index . 1 -}}

{{/* Validate parameters */}}
{{- $validationError := include "tarot.validateTemplateParameters" (list $templateDef $root.Values.tarot.parameters) -}}
{{- if $validationError -}}
  {{- fail $validationError -}}
{{- end -}}

apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  {{- if $root.Values.workflow.generateName }}
  generateName: {{ include "tarot.workflowName" $root }}
  {{- else }}
  name: {{ include "tarot.workflowName" $root }}
  {{- end }}
  namespace: {{ $root.Release.Namespace | quote }}
  labels:
    {{- include "tarot.labels" $root | nindent 4 }}
    kast.ing/template: {{ $templateDef.name | quote }}
    {{- if $root.Values.workflow.labels }}
    {{- $root.Values.workflow.labels | toYaml | nindent 4 }}
    {{- end }}
  {{- if $root.Values.workflow.annotations }}
  annotations:
    {{- $root.Values.workflow.annotations | toYaml | nindent 4 }}
  {{- end }}
spec:
  {{- include "tarot.generateTemplateRef" (list $root $templateDef) | nindent 2 }}
  
  {{/* Service Account */}}
  {{- if $root.Values.workflow.serviceAccount }}
  serviceAccountName: {{ $root.Values.workflow.serviceAccount | quote }}
  {{- end }}
  
  {{/* Workflow Arguments */}}
  {{- if $root.Values.tarot.parameters }}
  arguments:
    parameters:
      {{- include "tarot.generateWorkflowParameters" (list $root $root.Values.tarot.parameters) | nindent 6 }}
  {{- end }}
  
  {{/* Global workflow parameters */}}
  {{- if $root.Values.workflow.arguments }}
  {{- if not $root.Values.tarot.parameters }}
  arguments:
  {{- end }}
    {{- if $root.Values.workflow.arguments.parameters }}
    {{- if not $root.Values.tarot.parameters }}
    parameters:
    {{- end }}
      {{- $root.Values.workflow.arguments.parameters | toYaml | nindent 6 }}
    {{- end }}
  {{- end }}
  
  {{/* Node Selection */}}
  {{- if $root.Values.nodeSelector }}
  nodeSelector:
    {{- $root.Values.nodeSelector | toYaml | nindent 4 }}
  {{- end }}
  
  {{/* Tolerations */}}
  {{- if $root.Values.tolerations }}
  tolerations:
    {{- $root.Values.tolerations | toYaml | nindent 4 }}
  {{- end }}
  
  {{/* Affinity */}}
  {{- if $root.Values.affinity }}
  affinity:
    {{- $root.Values.affinity | toYaml | nindent 4 }}
  {{- end }}
  
  {{/* Security Context */}}
  {{- if $root.Values.securityContext }}
  securityContext:
    {{- $root.Values.securityContext | toYaml | nindent 4 }}
  {{- end }}
  
  {{/* Resource Management */}}
  {{- if $root.Values.resources }}
  {{- if or $root.Values.resources.limits $root.Values.resources.requests }}
  activeDeadlineSeconds: {{ $root.Values.resources.activeDeadlineSeconds | default 3600 }}
  {{- end }}
  {{- end }}
{{- end -}}

{{/*
Generate WorkflowTemplate resource for cluster registration
Parameters: (list $root $templateName $templateDef)
Returns: WorkflowTemplate resource definition
*/}}
{{- define "tarot.generateWorkflowTemplate" -}}
{{- $root := index . 0 -}}
{{- $templateName := index . 1 -}}
{{- $templateDef := index . 2 -}}

apiVersion: argoproj.io/v1alpha1
kind: WorkflowTemplate
metadata:
  name: {{ $templateName | quote }}
  namespace: {{ $root.Release.Namespace | quote }}
  labels:
    {{- include "tarot.labels" $root | nindent 4 }}
    kast.ing/template-type: workflow
    {{- if $templateDef.labels }}
    {{- $templateDef.labels | toYaml | nindent 4 }}
    {{- end }}
  {{- if $templateDef.annotations }}
  annotations:
    {{- $templateDef.annotations | toYaml | nindent 4 }}
  {{- end }}
spec:
  {{- $templateDef.template.spec | toYaml | nindent 2 }}
{{- end -}}

{{/*
Generate ClusterWorkflowTemplate resource for cluster-wide registration
Parameters: (list $root $templateName $templateDef)
Returns: ClusterWorkflowTemplate resource definition
*/}}
{{- define "tarot.generateClusterWorkflowTemplate" -}}
{{- $root := index . 0 -}}
{{- $templateName := index . 1 -}}
{{- $templateDef := index . 2 -}}

apiVersion: argoproj.io/v1alpha1
kind: ClusterWorkflowTemplate
metadata:
  name: {{ $templateName | quote }}
  labels:
    {{- include "tarot.labels" $root | nindent 4 }}
    kast.ing/template-type: cluster-workflow
    {{- if $templateDef.labels }}
    {{- $templateDef.labels | toYaml | nindent 4 }}
    {{- end }}
  {{- if $templateDef.annotations }}
  annotations:
    {{- $templateDef.annotations | toYaml | nindent 4 }}
  {{- end }}
spec:
  {{- $templateDef.template.spec | toYaml | nindent 2 }}
{{- end -}}
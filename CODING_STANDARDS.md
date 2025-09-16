# Kast Framework Coding Standards

This document defines the coding standards and best practices for developing Kast glyphs and trinkets to ensure consistency, maintainability, and quality across the framework.

## 🎯 Overview

Kast uses a standardized approach to Helm template development that ensures predictable patterns across all glyphs and trinkets. These standards have been implemented and validated as of the feature/coding-standards branch.

## 📐 Template Naming Convention

### Glyph Template Names
Use the pattern: `{glyphName}.{resourceType}`

```helm
# ✅ Correct Examples:
{{- define "istio.virtualService" }}
{{- define "vault.secret" }}
{{- define "summon.persistentVolumeClaim" }}
{{- define "certManager.certificate" }}

# ❌ Incorrect Examples:
{{- define "summon.persistanteVolumeClaim" }}  # Typo
{{- define "summon.pvc" }}                    # Abbreviation
{{- define "istio.vs" }}                      # Abbreviation
```

### File Naming
- Use descriptive names: `virtualService.tpl`, `certificate.yaml`
- Avoid abbreviations: `pvc.tpl` → `persistentVolumeClaim.tpl`
- Use consistent spelling: `statefulSet` not `statefullSet`

## 📋 Standard Parameter Passing

### Glyph Parameter Pattern
All glyphs must follow this standard parameter pattern:

```helm
# Standard Pattern:
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 -}}

# Usage:
{{- include "glyph.template" (list $root $glyphDefinition) }}
```

### Parameter Validation
Use the common validation helpers:

```helm
# Optional: Validate parameters using helper
{{- $params := include "common.extractGlyphParameters" . | fromYaml }}
{{- $root := $params.root }}
{{- $glyphDefinition := $params.glyphDefinition }}
```

## 📝 Documentation Standards

### Required Header Format
Every template must include this standardized header:

```helm
{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

{template.name} creates {description of what it does}.
{Optional: Integration details, special behavior}

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: {Resource} configuration object (index . 1)

Required Configuration:
- glyphDefinition.{requiredField}: {description}

Optional Configuration:
- glyphDefinition.{optionalField}: {description with default}

{Optional: Generated Resources section}
{Optional: Special behavior notes}

Usage: {{- include "template.name" (list $root $glyph) }}
*/}}
```

### Documentation Examples

#### Example 1: Simple Resource Template
```helm
{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

summon.persistentVolumeClaim creates PersistentVolumeClaim resources for volumes defined with type "pvc".
Automatically iterates through all volumes in .Values.volumes and creates PVCs for applicable ones.

Parameters:
- $root: Chart root context (accessed as . in the template)
- Reads .Values.volumes directly from root context

Volume Configuration:
- volume.type: must be "pvc" to generate PVC
- volume.name: optional custom PVC name (defaults to {chart-name}-{volume-key})
- volume.size: required storage size (e.g., "10Gi")
- volume.storageClassName: optional storage class
- volume.accessMode: optional access mode (defaults to "ReadWriteOnce")

Usage: {{- include "summon.persistentVolumeClaim" . }}
*/}}
```

#### Example 2: Complex Integration Template
```helm
{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

istio.virtualService creates Istio VirtualService resources for routing traffic to services.
Integrates with the runicIndexer system to find appropriate gateways based on selectors.

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: VirtualService configuration object (index . 1)

Required Configuration:
- glyphDefinition.enabled: must be true to generate resource

Optional Configuration:
- glyphDefinition.nameOverride: custom resource name (defaults to common.name + gateway.name)
- glyphDefinition.namespace: target namespace
- glyphDefinition.subdomain: subdomain for routing (inherits from spellbook/chapter)
- glyphDefinition.httpRules: HTTP routing rules array
- glyphDefinition.host: target service host (defaults to common.name.namespace.svc.cluster.local)

Usage: {{- include "istio.virtualService" (list $root $glyph) }}
*/}}
```

## 🏗️ Template Structure Standard

### Standard Glyph Template Structure
```helm
{{/*
[Documentation Header - see above]
*/}}
{{- define "glyph.resourceType" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 -}}

{{/* Optional: Parameter validation */}}
{{- if not $glyphDefinition.enabled }}
{{- else }}

{{/* Optional: External system integration (runicIndexer) */}}
{{- $externalResources := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.selector) "resource-type" $root.Values.chapter.name ) | fromJson) "results" }}

{{/* Resource generation */}}
{{- range $resource := $externalResources }}
---
apiVersion: {api.version}
kind: {ResourceKind}
metadata:
  name: {{ default (include "common.name" $root) $glyphDefinition.nameOverride }}
  labels:
    {{- include "common.labels" $root | nindent 4 }}
  {{- with $glyphDefinition.annotations }}
  annotations:
    {{- . | toYaml | nindent 4 }}
  {{- end }}
spec:
  # Resource-specific configuration
{{- end }}
{{- end }}
{{- end }}
```

## 🎭 Trinket Architecture Standard

### Trinket Template Structure
```helm
{{/*
[Documentation Header]
*/}}
{{- $root := . }}

{{/* Include base functionality */}}
{{- if .Values.workload.enabled -}}
{{- include "summon.workload.deployment" . }}
{{- end -}}

{{/* Conditional glyph integration */}}
{{- if .Values.service.enabled -}}
  {{- $glyph := merge .Values.service (dict "name" (include "common.name" $root)) }}
  {{- include "istio.virtualService" (list $root $glyph) }}
{{- end -}}

{{/* Additional glyphs as needed */}}
{{- if .Values.certificates.enabled -}}
  {{- $glyph := .Values.certificates }}
  {{- include "certManager.certificate" (list $root $glyph) }}
{{- end -}}
```

## ✅ Validation Patterns

### Use Validation Helpers
```helm
# Parameter validation
{{- if not $glyphDefinition -}}
  {{- fail "Glyph definition is required" -}}
{{- end -}}

# Set defaults
{{- if not (hasKey $glyphDefinition "enabled") -}}
  {{- $_ := set $glyphDefinition "enabled" true -}}
{{- end -}}

# Validate required fields
{{- if and $glyphDefinition.enabled (not $glyphDefinition.dnsNames) -}}
  {{- fail "dnsNames is required when certificate is enabled" -}}
{{- end -}}
```

## 🔍 Best Practices

### 1. Consistency
- Always use the standard parameter pattern `(list $root $glyphDefinition)`
- Follow naming conventions consistently
- Use common helper functions for labels, names, annotations

### 2. Documentation
- Document all parameters and their defaults
- Include usage examples
- Explain integration points (runicIndexer, lexicon)

### 3. Error Handling
- Validate required parameters
- Provide meaningful error messages
- Set sensible defaults where appropriate

### 4. Testing
- Test templates with helm template command
- Test both basic and complex configurations
- Verify integration with runicIndexer and lexicon

## 📊 Implementation Status

As of feature/coding-standards branch:

- ✅ **Phase 1**: Fixed naming inconsistencies (`persistante` → `persistent`)
- ✅ **Phase 2**: Standardized documentation headers across key templates
- ✅ **Phase 3**: Fixed template naming conventions (`statefullSet` → `statefulSet`)
- ✅ **Phase 4**: Standardized parameter passing patterns
- ✅ **Phase 5**: Added validation helpers in `common/templates/validation.tpl`
- ✅ **Phase 6**: Created comprehensive coding standards documentation

## 🚀 Future Enhancements

1. **Automated Linting**: Develop pre-commit hooks to enforce standards
2. **Template Generator**: Create scaffolding tools for new glyphs
3. **Integration Tests**: Automated testing of glyph interactions
4. **Performance Optimization**: Template rendering performance improvements

## 📖 References

- [Helm Template Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Kubernetes Resource Naming](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/)
- [YAML Style Guide](https://yaml.org/spec/1.2/spec.html)

---

This document is maintained alongside the Kast framework and should be updated when new patterns or standards are established.
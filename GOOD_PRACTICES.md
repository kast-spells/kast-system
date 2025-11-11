# Kast Framework Good Practices Guide

A comprehensive guide to best practices, patterns, and anti-patterns for developing with the kast-system framework.

## Table of Contents

1. [TDD Best Practices](#tdd-best-practices)
2. [Glyph Development Best Practices](#glyph-development-best-practices)
3. [Book/Chapter/Spell Organization](#bookchapterspell-organization)
4. [Lexicon Design Guidelines](#lexicon-design-guidelines)
5. [Testing Patterns and Anti-Patterns](#testing-patterns-and-anti-patterns)
6. [Code Review Checklist](#code-review-checklist)
7. [Common Pitfalls and Solutions](#common-pitfalls-and-solutions)
8. [Performance Considerations](#performance-considerations)
9. [Security Best Practices](#security-best-practices)
10. [GitOps Workflow Recommendations](#gitops-workflow-recommendations)

---

## TDD Best Practices

### The Sacred TDD Cycle: Red-Green-Refactor

#### Understanding the Mechanics

The TDD commands have specific behaviors that enforce discipline:

**Red Phase (`make tdd-red`)**
- Uses `||` operator to celebrate failures
- Runs tests expecting them to fail
- Confirms your test actually tests something
- **When to use:** After writing new examples, before implementation

**Green Phase (`make tdd-green`)**
- Direct execution, no error suppression
- Tests MUST pass or Make exits with error
- Confirms your implementation works
- **When to use:** After implementing features

**Refactor Phase (`make tdd-refactor`)**
- Runs comprehensive test suite (`test-all`)
- Ensures refactoring didn't break anything
- Includes snapshots, glyphs, and all validations
- **When to use:** After improving code quality

#### The Golden Rules

1. **ALWAYS write tests first**
   ```bash
   # DO THIS
   make create-example CHART=summon EXAMPLE=new-feature
   # Edit the example file
   make tdd-red
   # Implement feature
   make tdd-green

   # DON'T DO THIS
   # Implement feature first, then add tests
   ```

2. **One test at a time**
   - Focus on making ONE test pass
   - Don't write multiple failing tests
   - Each test should validate one specific behavior

3. **Minimal implementation**
   ```go
   // RED: Test expects PodDisruptionBudget
   // GREEN: Add minimal template to generate PDB
   // REFACTOR: Add validation, defaults, documentation
   ```

4. **Never skip the red phase**
   - If test passes immediately, it might not be testing anything
   - Seeing it fail confirms it's actually validating behavior

5. **Commit only passing tests**
   - All tests must pass before committing
   - Run `make test-all` before every commit

### TDD Workflow Patterns

#### Adding New Chart Features

```bash
# 1. RED PHASE - Write failing test
make create-example CHART=summon EXAMPLE=pod-disruption
cat > charts/summon/examples/pod-disruption.yaml <<EOF
workload:
  enabled: true
  type: deployment
  replicas: 3

podDisruptionBudget:
  enabled: true
  minAvailable: 2
EOF

# 2. Verify failure
make tdd-red
# Output: ❌ summon-pod-disruption (expectations failed)
#         ✅ Good! Tests are failing - now implement

# 3. GREEN PHASE - Implement
# Create charts/summon/templates/pod-disruption-budget.yaml

# 4. Verify success
make tdd-green
# Output: ✅ summon-pod-disruption

# 5. REFACTOR PHASE - Improve
# Add validation, defaults, documentation
make tdd-refactor
# Output: ✅ All tests pass
```

#### Adding New Glyph Features

```bash
# 1. RED PHASE - Create example
cat > charts/glyphs/vault/examples/dynamic-db-creds.yaml <<EOF
glyphs:
  vault:
    - type: databaseRole
      name: app-db-access
      enabled: true
EOF

# 2. Test failure
make glyphs vault
# Output: ❌ vault-dynamic-db-creds (template not found)

# 3. GREEN PHASE - Implement template
# Create charts/glyphs/vault/templates/database-role.tpl

# 4. Test success
make glyphs vault
# Output: ✅ vault-dynamic-db-creds

# 5. Lock in expected output
make generate-expected GLYPH=vault

# 6. REFACTOR PHASE
make glyphs vault
# Output: ✅ vault-dynamic-db-creds (output matches expected)
```

### Five Whys for Problem Solving

When encountering errors, ask "Why?" five times to find root causes:

```
Problem: Tests failing after adding new feature

Why? → Template rendering fails
Why? → Missing parameter validation
Why? → Parameter extraction pattern wrong
Why? → Using . instead of (list $root $glyph)
Why? → Didn't follow coding standards

Root Cause: Need to standardize parameter passing across all templates
Solution: Update template to use standard pattern + add validation
```

### Test-First Thinking

**Good example:**
```yaml
# Write this FIRST (the test)
workload:
  enabled: true
  type: statefulset
  volumeClaimTemplates:
    data:
      size: 10Gi
      storageClass: fast-ssd

# Then implement the feature
# Then verify it works
```

**Bad example:**
```yaml
# Implementing features then trying to write tests that match
# This leads to confirmation bias and weak tests
```

---

## Glyph Development Best Practices

### Template Structure Standards

#### Standard Glyph Template Pattern

```go
{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

glyph.resourceType creates [description].
[Optional: Integration details, special behavior]

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: [Resource] configuration object (index . 1)

Required Configuration:
- glyphDefinition.requiredField: [description]

Optional Configuration:
- glyphDefinition.optionalField: [description with default]

Usage: {{- include "glyph.resourceType" (list $root $glyph) }}
*/}}
{{- define "glyph.resourceType" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}

{{/* Parameter validation */}}
{{- if not $glyphDefinition.enabled }}
{{- else }}

{{/* Optional: External system integration */}}
{{- $externalResources := get (include "runicIndexer.runicIndexer"
    (list $root.Values.lexicon
          (default dict $glyphDefinition.selector)
          "resource-type"
          $root.Values.chapter.name) | fromJson) "results" }}

{{/* Resource generation */}}
{{- range $resource := $externalResources }}
---
apiVersion: {api.version}
kind: {ResourceKind}
metadata:
  name: {{ default (include "common.name" $root) $glyphDefinition.nameOverride }}
  labels:
    {{- include "common.labels" $root | nindent 4 }}
spec:
  # Resource-specific configuration
{{- end }}
{{- end }}
{{- end }}
```

### Naming Conventions

#### Template Names

```go
// ✅ CORRECT
{{- define "istio.virtualService" }}
{{- define "vault.secret" }}
{{- define "summon.persistentVolumeClaim" }}
{{- define "certManager.certificate" }}

// ❌ INCORRECT
{{- define "summon.pvc" }}              // Abbreviation
{{- define "istio.vs" }}                // Abbreviation
{{- define "summon.persistante" }}      // Typo
{{- define "summon.statefullSet" }}     // Typo
```

#### File Names

```
✅ CORRECT:
- virtualService.tpl
- persistentVolumeClaim.tpl
- certificate.yaml
- _helpers.tpl

❌ INCORRECT:
- pvc.tpl                    # Abbreviation
- VirtualService.tpl         # Capital letter
- secret-template.tpl        # Redundant suffix
```

### Parameter Passing

#### Standard Pattern (ALWAYS use this)

```go
{{- define "glyph.template" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}

// Access glyph configuration
name: {{ $glyphDefinition.name }}
enabled: {{ default true $glyphDefinition.enabled }}

// Access root context
release: {{ $root.Release.Name }}
namespace: {{ $root.Release.Namespace }}
{{- end }}

// Invocation
{{- include "glyph.template" (list $root $glyphDefinition) }}
```

#### Common Glyph Exception

```go
// Common glyph templates take $root directly (not list)
{{- include "common.name" $root }}
{{- include "common.labels" $root | nindent 4 }}
```

### Validation and Defaults

#### Always Validate Required Fields

```go
{{- if not $glyphDefinition.name }}
  {{- fail "glyph.resource requires 'name' field" }}
{{- end }}

{{- if not (hasKey $glyphDefinition "type") }}
  {{- fail "glyph.resource requires 'type' field" }}
{{- end }}

{{- if and $glyphDefinition.replicas (lt ($glyphDefinition.replicas | int) 0) }}
  {{- fail "replicas must be >= 0" }}
{{- end }}
```

#### Provide Sensible Defaults

```go
// Simple default
enabled: {{ default true $glyphDefinition.enabled }}
replicas: {{ default 1 $glyphDefinition.replicas }}

// Conditional default
timeout: {{ default (ternary 300 60 $glyphDefinition.production) $glyphDefinition.timeout }}

// Default from root values
image: {{ default $root.Values.defaultImage $glyphDefinition.image }}
```

### Single Responsibility Principle

```go
// ✅ GOOD: One template per resource type
{{- define "myglyph.deployment" }}    // Generates Deployment
{{- define "myglyph.service" }}       // Generates Service
{{- define "myglyph.configmap" }}     // Generates ConfigMap

// ❌ BAD: One template generating multiple unrelated resources
{{- define "myglyph.everything" }}    // Generates Deployment + Service + ConfigMap
```

---

## Book/Chapter/Spell Organization

### Book Structure

```yaml
# bookrack/my-book/index.yaml
name: my-book

# Trinkets (special charts)
trinkets:
  kaster:
    key: glyphs
    repository: https://github.com/kast-spells/kast-system.git
    path: ./charts/kaster
    revision: master

# Default trinket for regular spells
defaultTrinket:
  repository: https://github.com/kast-spells/kast-system.git
  path: ./charts/summon
  revision: master

# Book-wide appendix (shared configuration)
appendix:
  lexicon:
    # Infrastructure resources available to all chapters

# Chapters (environments/namespaces)
chapters:
  - development
  - staging
  - production
```

### Chapter Organization

```
bookrack/my-book/
├── index.yaml                      # Book definition
├── _appendix/
│   └── lexicon.yaml               # Book-wide infrastructure
├── development/
│   ├── values.yaml                # Chapter configuration
│   ├── service-a/
│   │   └── values.yaml           # Spell for service-a
│   └── service-b/
│       └── values.yaml           # Spell for service-b
├── staging/
│   ├── values.yaml
│   ├── service-a/
│   │   └── values.yaml
│   └── service-b/
│       └── values.yaml
└── production/
    ├── values.yaml
    ├── service-a/
    │   └── values.yaml
    └── service-b/
        └── values.yaml
```

### Spell (Application) Organization

#### Basic Spell Structure

```yaml
# bookrack/my-book/production/my-app/values.yaml

# Workload configuration
workload:
  enabled: true
  type: deployment
  replicas: 3

# Container image
image:
  name: myapp
  tag: v1.2.3
  pullPolicy: IfNotPresent

# Service exposure
service:
  enabled: true
  type: ClusterIP
  ports:
    - port: 80
      name: http

# Glyphs (infrastructure integrations)
glyphs:
  istio:
    external-route:
      type: virtualService
      enabled: true
      selector:
        access: external
        environment: production

  vault:
    db-credentials:
      type: secret
      enabled: true
      format: env
      keys:
        - DB_USERNAME
        - DB_PASSWORD
```

### Hierarchical Configuration Strategy

#### Appendix (Book-wide)

Use for:
- Shared infrastructure (databases, message queues)
- Organization-wide defaults
- Cross-chapter resources

```yaml
# _appendix/lexicon.yaml
appendix:
  lexicon:
    - name: org-wide-vault
      type: vault
      url: https://vault.company.com
      labels:
        default: book
```

#### Chapter Values

Use for:
- Environment-specific configuration
- Chapter-wide defaults
- Resource quotas and limits

```yaml
# production/values.yaml
chapter:
  name: production
  namespace: production

# Environment-specific infrastructure
lexicon:
  - name: production-database
    type: database
    host: postgres.prod.svc
    labels:
      environment: production
      default: chapter
```

#### Spell Values

Use for:
- Application-specific configuration
- Service parameters
- Feature flags

```yaml
# production/my-app/values.yaml
workload:
  enabled: true
  replicas: 5  # Production needs more replicas

resources:
  limits:
    memory: 2Gi  # Production needs more memory
```

### Configuration Inheritance

```
Book Appendix (lowest priority)
    ↓
Chapter Values (medium priority)
    ↓
Spell Values (highest priority)
```

Example:
```yaml
# Book appendix: 1 replica default
# Chapter values: 2 replicas for staging
# Spell values: 5 replicas for critical service
# Result: Spell gets 5 replicas
```

---

## Lexicon Design Guidelines

### Resource Entry Structure

```yaml
lexicon:
  - name: descriptive-unique-name
    type: resource-type
    labels:
      # Selection labels
      environment: production
      region: us-west-2
      tier: primary
      # Default strategy
      default: book|chapter
    # Resource-specific fields
    field1: value1
    field2: value2
```

### Label Design Patterns

#### Hierarchical Labels

```yaml
labels:
  # Broadest - Environment
  environment: production

  # Medium - Access/Region
  access: external
  region: us-west-2

  # Narrowest - Specific features
  ssl: enabled
  tier: primary
```

#### Default Strategy

**Book Default** - Organization-wide fallback:
```yaml
labels:
  default: book
# Used when: No exact match and no chapter default
```

**Chapter Default** - Environment-specific fallback:
```yaml
labels:
  default: chapter
  environment: production
chapter: production
# Used when: No exact match in current chapter
```

**No Default** - Must be explicitly selected:
```yaml
labels:
  access: admin-only
  security-level: high
# Used when: Must never be selected accidentally
```

### Resource Type Conventions

```yaml
# Infrastructure types
type: istio-gw          # Istio Gateway
type: vault             # Vault server
type: database          # Database server
type: eventbus          # Argo Events EventBus
type: storage-class     # StorageClass

# Integration types
type: oauth-provider    # OAuth/OIDC provider
type: monitoring        # Monitoring system
type: logging           # Logging aggregator
```

### Naming Best Practices

```yaml
# ✅ GOOD: Descriptive and specific
- name: external-production-gateway
- name: vault-production-server
- name: postgres-primary-database
- name: jetstream-production-eventbus

# ❌ BAD: Vague and ambiguous
- name: gateway1
- name: server
- name: db
- name: bus
```

### Lexicon Organization

#### Book-Level Lexicon

```yaml
# _appendix/infrastructure.yaml
appendix:
  lexicon:
    # Shared across all chapters
    - name: org-wide-vault
      type: vault
      labels:
        default: book
      url: https://vault.company.com

    # Production-only (no default)
    - name: production-database
      type: database
      labels:
        environment: production
      host: postgres.prod.svc
```

#### Chapter-Level Lexicon

```yaml
# staging/values.yaml
lexicon:
  # Chapter-specific resources
  - name: staging-gateway
    type: istio-gw
    labels:
      environment: staging
      default: chapter
    chapter: staging
    gateway: istio-system/staging-gateway
```

### Selector Design

#### Start Broad, Get Specific

Development:
```yaml
selector:
  environment: dev  # Broad - matches any dev resource
```

Production:
```yaml
selector:
  environment: production
  region: us-west-2
  tier: primary  # Specific - matches exact resource
```

#### Leverage Fallbacks

```yaml
# Try specific resource
selector:
  environment: production
  region: us-west-2

# If no match, falls back to:
# 1. Chapter default (if in production chapter)
# 2. Book default (organization-wide)
```

---

## Testing Patterns and Anti-Patterns

### Testing Patterns (DO THESE)

#### 1. Comprehensive Example Coverage

```
charts/summon/examples/
├── basic-deployment.yaml          # Minimal valid configuration
├── statefulset-with-storage.yaml  # StatefulSet with PVCs
├── job-with-config.yaml           # Job workload
├── cronjob-schedule.yaml          # CronJob workload
├── complex-production.yaml        # All features enabled
├── autoscaling.yaml               # HPA configuration
└── service-mesh.yaml              # Istio integration
```

#### 2. Resource Completeness Validation

The validation script ensures all expected resources are generated:

```bash
# Example expectations:
# workload.enabled=true → Must generate Deployment/StatefulSet/Job
# service.enabled=true → Must generate Service
# autoscaling.enabled=true → Must generate HPA
# volumes.*.type=pvc → Must generate PVC (if not volumeClaimTemplate)
```

#### 3. Snapshot Testing

```bash
# Generate snapshots for new features
make generate-snapshots CHART=summon

# Update snapshot after intentional changes
make update-snapshot CHART=summon EXAMPLE=basic-deployment

# Show differences
make show-snapshot-diff CHART=summon EXAMPLE=basic-deployment
```

#### 4. Glyph Testing Through Kaster

```bash
# ✅ CORRECT: Test glyph through kaster orchestration
make glyphs vault

# ❌ INCORRECT: Test glyph directly (will fail)
helm template charts/glyphs/vault
```

#### 5. Covenant Book Testing

```bash
# Test main covenant (ApplicationSet generation)
make test-covenant-book BOOK=covenant-tyl

# Test specific chapter
make test-covenant-chapter BOOK=covenant-tyl CHAPTER=tyl

# Test all chapters (RECOMMENDED)
make test-covenant-all-chapters BOOK=covenant-tyl
```

### Testing Anti-Patterns (AVOID THESE)

#### 1. Implementation-First Testing

```yaml
# ❌ BAD: Writing tests to match existing implementation
# This leads to weak tests that don't validate behavior

# ✅ GOOD: Write tests defining expected behavior first
# Then implement to make tests pass
```

#### 2. Single Example per Chart

```
# ❌ BAD
charts/summon/examples/
└── basic.yaml  # Only one scenario

# ✅ GOOD
charts/summon/examples/
├── basic-deployment.yaml
├── statefulset-with-storage.yaml
├── complex-production.yaml
└── autoscaling.yaml
```

#### 3. Ignoring Test Failures

```bash
# ❌ BAD: Continuing development with failing tests
make test
# Output: ❌ Some tests failing
# Continues working on new features

# ✅ GOOD: Fix all failures before proceeding
make test
# Output: ❌ Some tests failing
# Stops, investigates, fixes root cause
```

#### 4. Manual Testing Only

```bash
# ❌ BAD: Only testing manually with kubectl
helm install test-release charts/summon
kubectl get pods

# ✅ GOOD: Automated testing with TDD commands
make test-all
```

#### 5. Not Testing Edge Cases

```yaml
# ❌ BAD: Only testing happy path
workload:
  enabled: true
  replicas: 2

# ✅ GOOD: Testing edge cases
workload:
  enabled: false  # Disabled workload
  replicas: 0     # Zero replicas
# (empty)         # Missing configuration
```

### Test Coverage Checklist

- [ ] Basic configuration (minimal valid input)
- [ ] Advanced configuration (all features enabled)
- [ ] Edge cases (empty, zero, nil values)
- [ ] Validation errors (invalid inputs should fail)
- [ ] Integration scenarios (multiple glyphs together)
- [ ] Resource completeness (all expected K8s resources)
- [ ] Snapshot matching (output matches expected)
- [ ] K8s schema validation (dry-run succeeds)

---

## Code Review Checklist

### Pre-Review (Author)

- [ ] All tests passing (`make test-all`)
- [ ] TDD cycle followed (Red → Green → Refactor)
- [ ] Examples added for new features
- [ ] Snapshots generated/updated
- [ ] Documentation updated
- [ ] Copyright headers present
- [ ] No hardcoded values (use lexicon/runic indexer)
- [ ] Validation for required parameters
- [ ] Sensible defaults for optional parameters

### Template Review

- [ ] Follows naming conventions (no abbreviations, correct spelling)
- [ ] Standard parameter pattern: `(list $root $glyphDefinition)`
- [ ] Uses common glyph for labels/names
- [ ] Proper documentation header
- [ ] Error messages are informative
- [ ] No deprecated functions
- [ ] Conditional resources use `{{- if }}` properly

### Testing Review

- [ ] Examples cover all code paths
- [ ] Edge cases tested
- [ ] Resource completeness validated
- [ ] Snapshots match expected output
- [ ] Integration with other glyphs tested

### Documentation Review

- [ ] Template parameters documented
- [ ] Usage examples provided
- [ ] Integration points explained (runic indexer, lexicon)
- [ ] Special behaviors noted
- [ ] Added to relevant reference docs

### Security Review

- [ ] No secrets in values files
- [ ] Secrets managed through Vault
- [ ] RBAC properly configured
- [ ] Network policies considered
- [ ] No privileged containers (unless required + documented)

---

## Common Pitfalls and Solutions

### 1. Wrong Parameter Pattern

#### Pitfall

```go
{{- define "myglyph.resource" }}
{{- $root := . }}  // ❌ Wrong!
{{- $glyph := .Values.glyph }}  // ❌ Wrong!
```

#### Solution

```go
{{- define "myglyph.resource" }}
{{- $root := index . 0 -}}  // ✅ Correct
{{- $glyphDefinition := index . 1 }}  // ✅ Correct
```

### 2. Testing Glyphs Directly

#### Pitfall

```bash
# ❌ This will fail
helm template charts/glyphs/vault
```

#### Solution

```bash
# ✅ Test through kaster
make glyphs vault
```

### 3. Hardcoded Infrastructure References

#### Pitfall

```yaml
# ❌ Hardcoded gateway
spec:
  gateways:
    - istio-system/external-gateway
```

#### Solution

```go
// ✅ Use runic indexer
{{- $gateways := get (include "runicIndexer.runicIndexer"
    (list $root.Values.lexicon $glyphDefinition.selector "istio-gw" $root.Values.chapter.name)
    | fromJson) "results" }}
{{- range $gateway := $gateways }}
spec:
  gateways:
    - {{ $gateway.gateway }}
{{- end }}
```

### 4. Missing Validation

#### Pitfall

```go
{{- define "myglyph.resource" }}
// ❌ No validation - will fail with cryptic error
name: {{ $glyphDefinition.name }}
```

#### Solution

```go
{{- define "myglyph.resource" }}
// ✅ Validate required fields
{{- if not $glyphDefinition.name }}
  {{- fail "myglyph.resource requires 'name' field" }}
{{- end }}
name: {{ $glyphDefinition.name }}
```

### 5. No Defaults for Optional Fields

#### Pitfall

```go
// ❌ Will fail if field not provided
replicas: {{ $glyphDefinition.replicas }}
```

#### Solution

```go
// ✅ Provide sensible default
replicas: {{ default 1 $glyphDefinition.replicas }}
```

### 6. Incorrect Common Glyph Usage

#### Pitfall

```go
// ❌ Wrong - common glyph doesn't take list
{{- include "common.name" (list $root $glyph) }}
```

#### Solution

```go
// ✅ Correct - common glyph takes $root directly
{{- include "common.name" $root }}
```

### 7. Not Following Five Whys

#### Pitfall

```
Error: Template rendering failed
Action: Change random things hoping to fix it
Result: More things broken
```

#### Solution

```
Error: Template rendering failed
Why? → Parameter access failed
Why? → $glyphDefinition is nil
Why? → Wrong parameter extraction pattern
Why? → Used . instead of (list $root $glyph)
Why? → Didn't follow coding standards
Fix: Update to standard parameter pattern
```

### 8. Skipping Test Phases

#### Pitfall

```bash
# ❌ Implementing without seeing tests fail
make create-example CHART=summon EXAMPLE=new-feature
# Edit template immediately
make tdd-green
```

#### Solution

```bash
# ✅ Follow proper TDD cycle
make create-example CHART=summon EXAMPLE=new-feature
make tdd-red        # See it fail
# Edit template
make tdd-green      # See it pass
# Improve code
make tdd-refactor   # Verify still passes
```

---

## Performance Considerations

### Template Rendering Performance

#### Avoid Deep Nesting

```go
// ❌ BAD: Deep nested loops
{{- range $chapter := .Values.chapters }}
  {{- range $spell := $chapter.spells }}
    {{- range $glyph := $spell.glyphs }}
      {{- range $resource := $glyph.resources }}
        // This is slow
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

// ✅ GOOD: Flatten when possible
{{- $allResources := list }}
{{- range $chapter := .Values.chapters }}
  {{- $allResources = concat $allResources $chapter.resources }}
{{- end }}
{{- range $resource := $allResources }}
  // Process once
{{- end }}
```

#### Cache Expensive Operations

```go
// ❌ BAD: Repeated expensive calls
{{- range $item := .Values.items }}
  name: {{ include "expensive.computation" $root }}
{{- end }}

// ✅ GOOD: Compute once, reuse
{{- $computedValue := include "expensive.computation" $root }}
{{- range $item := .Values.items }}
  name: {{ $computedValue }}
{{- end }}
```

#### Minimize Lexicon Queries

```go
// ❌ BAD: Query lexicon in loop
{{- range $service := .Values.services }}
  {{- $gateway := get (include "runicIndexer.runicIndexer" ...) "results" }}
{{- end }}

// ✅ GOOD: Query once, reuse
{{- $gateways := get (include "runicIndexer.runicIndexer" ...) "results" }}
{{- range $service := .Values.services }}
  {{- range $gateway := $gateways }}
    // Use cached gateway
  {{- end }}
{{- end }}
```

### Example File Size

Keep examples focused and reasonably sized:

```yaml
# ✅ GOOD: Focused example (< 100 lines)
workload:
  enabled: true
  type: deployment

service:
  enabled: true

# ❌ BAD: Kitchen sink example (> 500 lines)
# Every possible configuration option
# Makes tests slow and hard to debug
```

---

## Security Best Practices

### Secret Management

#### Never Hardcode Secrets

```yaml
# ❌ NEVER DO THIS
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
stringData:
  password: "hardcoded-password"  # NEVER!
```

#### Use Vault Integration

```yaml
# ✅ CORRECT: Use Vault glyph
glyphs:
  vault:
    my-secret:
      type: secret
      enabled: true
      format: env
      keys:
        - DB_PASSWORD
        - API_KEY
```

### RBAC Configuration

#### Principle of Least Privilege

```yaml
# ✅ GOOD: Minimal permissions
serviceAccount:
  enabled: true

rbac:
  enabled: true
  rules:
    - apiGroups: [""]
      resources: ["configmaps"]
      verbs: ["get", "list"]  # Only what's needed
```

```yaml
# ❌ BAD: Excessive permissions
rbac:
  enabled: true
  rules:
    - apiGroups: ["*"]
      resources: ["*"]
      verbs: ["*"]  # Too permissive!
```

### Network Policies

#### Default Deny

```yaml
# ✅ GOOD: Explicit allow
networkPolicy:
  enabled: true
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
      - podSelector:
          matchLabels:
            app: allowed-app
```

### Container Security

#### Non-Root Containers

```yaml
# ✅ GOOD: Run as non-root
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  capabilities:
    drop:
      - ALL
```

```yaml
# ❌ BAD: Running as root
securityContext:
  runAsUser: 0  # Root user
  privileged: true  # Privileged container
```

### Image Security

#### Use Specific Tags

```yaml
# ✅ GOOD: Specific version
image:
  name: myapp
  tag: v1.2.3-sha256-abc123
  pullPolicy: IfNotPresent
```

```yaml
# ❌ BAD: Latest tag
image:
  name: myapp
  tag: latest  # Unpredictable
```

---

## GitOps Workflow Recommendations

### Branch Strategy

```
master (or main)
  ↓
feature/descriptive-name  # Feature development
  ↓
PR → Review → Merge
```

### Commit Message Format

```
feat(component): Short description

Detailed explanation of changes.

- Added X feature
- Fixed Y issue
- Refactored Z

TDD cycle: Red → Green → Refactor
Tests: make test-all passing
```

### Pre-Commit Checklist

```bash
# 1. Run all tests
make test-all

# 2. Verify test status
make test-status

# 3. Lint charts
make lint

# 4. Check for uncommitted files
git status

# 5. Review changes
git diff

# 6. Commit with descriptive message
git commit -m "feat(summon): Add PodDisruptionBudget support"
```

### ArgoCD Integration

#### Application Naming

```yaml
# ✅ GOOD: Descriptive application names
metadata:
  name: my-book-production-my-app
  # Pattern: {book}-{chapter}-{spell}
```

#### Sync Policies

```yaml
# ✅ GOOD: Automatic sync for dev/staging
syncPolicy:
  automated:
    prune: true
    selfHeal: true

# ✅ GOOD: Manual sync for production
syncPolicy:
  automated: null  # Manual approval required
```

### Release Process

1. **Development**
   ```bash
   # Feature branch
   git checkout -b feature/new-feature
   # TDD development
   make tdd-red
   # Implement
   make tdd-green
   # Refactor
   make tdd-refactor
   ```

2. **Testing**
   ```bash
   # Comprehensive testing
   make test-all
   # Verify no regressions
   make test-status
   ```

3. **Review**
   - Create PR
   - Code review
   - Address feedback
   - Retest

4. **Merge**
   ```bash
   # Merge to master
   git checkout master
   git merge feature/new-feature
   git push origin master
   ```

5. **Deploy**
   - ArgoCD detects changes
   - Auto-sync or manual approval
   - Monitor deployment

---

## Summary

### Golden Rules

1. **TDD is mandatory** - Red → Green → Refactor
2. **Test first, implement second** - Always
3. **Follow naming conventions** - No abbreviations
4. **Use standard patterns** - (list $root $glyphDefinition)
5. **Validate inputs** - Fail fast with clear messages
6. **Provide defaults** - Sensible fallbacks
7. **Document everything** - Parameters, usage, examples
8. **Never hardcode** - Use lexicon and runic indexer
9. **Security first** - Vault, RBAC, least privilege
10. **GitOps workflow** - Automated, repeatable, auditable

### Quick Reference

```bash
# TDD Cycle
make tdd-red          # See it fail
make tdd-green        # Make it pass
make tdd-refactor     # Keep it passing

# Testing
make test-all         # Full test suite
make test-status      # Coverage report
make glyphs <name>    # Test specific glyph

# Development
make create-example CHART=<chart> EXAMPLE=<name>
make generate-snapshots CHART=<chart>
make update-snapshot CHART=<chart> EXAMPLE=<name>
```

### Additional Resources

- [CLAUDE.md](CLAUDE.md) - TDD philosophy and workflow
- [CODING_STANDARDS.md](CODING_STANDARDS.md) - Template standards
- [GLYPH_DEVELOPMENT.md](docs/GLYPH_DEVELOPMENT.md) - Glyph guide
- [LEXICON.md](docs/LEXICON.md) - Infrastructure discovery
- [TDD_COMMANDS.md](docs/TDD_COMMANDS.md) - Testing commands

---

**Remember:** Good practices aren't just rules - they're lessons learned from mistakes. Follow them to avoid common pitfalls and build reliable, maintainable Kubernetes deployments.

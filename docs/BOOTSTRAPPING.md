# Bootstrapping Guide

Complete guide for bootstrapping a Kubernetes cluster with ArgoCD and runik-system from scratch.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [ArgoCD Installation](#argocd-installation)
4. [runik-system Setup](#runik-system-setup)
5. [First Deployment](#first-deployment)
6. [Troubleshooting](#troubleshooting)
7. [Next Steps](#next-steps)

## Overview

This guide walks you through setting up a complete GitOps workflow using:
- **Kubernetes cluster** (any distribution: kind, k3s, EKS, GKE, AKS, on-prem)
- **ArgoCD** (from official Helm chart)
- **runik-system** (TDD Kubernetes deployment framework)

**Target audience:** Single cluster setup, cloud-agnostic

**Time estimate:** 30-45 minutes

**Architecture:**
```
Git Repository (bookrack/)
    ↓
ArgoCD (Apps of Apps pattern)
    ↓
Librarian (Book/Chapter/Spell → ArgoCD Applications)
    ↓
Kaster + Summon (Glyph orchestration + Workloads)
    ↓
Kubernetes Resources (Deployments, Services, etc.)
```

## Prerequisites

### Required Tools

Install these tools before proceeding:

| Tool | Minimum Version | Purpose | Installation |
|------|----------------|---------|--------------|
| **kubectl** | 1.25+ | Kubernetes CLI | [kubernetes.io](https://kubernetes.io/docs/tasks/tools/) |
| **helm** | 3.8+ | Package manager | [helm.sh](https://helm.sh/docs/intro/install/) |
| **git** | 2.30+ | Version control | [git-scm.com](https://git-scm.com/downloads) |

### Verify Installation

```bash
# Verify kubectl
kubectl version --client
# Expected: Client Version: v1.25.0 or higher

# Verify Helm
helm version
# Expected: version.BuildInfo{Version:"v3.8" or higher}

# Verify git
git --version
# Expected: git version 2.30.0 or higher
```

### Kubernetes Cluster Requirements

**Minimum specifications:**
- **Kubernetes version:** 1.25.0+
- **Nodes:** 1+ (3+ recommended for HA)
- **CPU:** 2+ cores per node
- **Memory:** 4GB+ per node
- **Storage:** StorageClass with dynamic provisioning (optional but recommended)

**Supported distributions:**
- **Local dev:** kind, minikube, k3d, Docker Desktop
- **Cloud:** EKS, GKE, AKS, CIVO, DigitalOcean
- **On-premises:** kubeadm, k3s, RKE2, Talos, OpenShift


## ArgoCD Installation

### 1. Add ArgoCD Helm Repository

```bash
# Add official ArgoCD Helm repository
helm repo add argo https://argoproj.github.io/argo-helm

# Update repository cache
helm repo update

# Verify repository was added
helm search repo argo/argo-cd
```

### 2. Prepare ArgoCD Values

You can create a custom `values.yaml` file for ArgoCD configuration.

**Example spell reference:** Check the example ArgoCD spell at [bookrack/the-example-book/intro/argocd.yaml](https://github.com/runik-spells/runik-system/blob/master/bookrack/the-example-book/intro/argocd.yaml)

**Extract values from example spell:**
```bash
# Get values configuration
cat path/to/your/argocd.yaml | yq .values

# Get chart revision
cat path/to/your/argocd.yaml | yq .revision
```

Create your own `values.yaml` file based on your requirements (ingress, HA, SSO, etc.).

### 3. Install ArgoCD

```bash
# Install ArgoCD with custom values
helm upgrade --install --create-namespace argocd argo/argo-cd \
  --namespace argocd \
  --values values.yaml
```

## runik-system Setup

### 1. Create Your Bookrack Repository

Create your own repository for configuration management using the Book/Chapter/Spell pattern. This is YOUR repository where you'll store all your application configurations (spells). runik-system will be added as a library (submodule) to provide access to charts (librarian, kaster, summon, glyphs).

**Important:**
- `bookrack/` = Your configuration (spells, books, chapters) - lives in YOUR repository
- Your spells reference runik-system charts but are NOT stored inside the submodule

```bash
# Create YOUR bookrack repository directory
mkdir -p ~/my-bookrack
cd ~/my-bookrack

# Initialize YOUR git repository
git init

# Add runik-system as submodule (library for charts only)
git submodule add https://github.com/runik-spells/librarian.git

# Initialize submodule
git submodule update --init --recursive
```

**What you just created:**
```
my-bookrack/                    # YOUR repository
│   └── runik-system/            # Submodule (library)
│       ├── charts/
│       │   ├── glyphs/         # Glyph templates
│       │   ├── kaster/         # Glyph orchestrator
│       │   └── summon/         # Workload chart
│       └── librarian/          # ArgoCD Apps of Apps
└── bookrack/                   # YOUR configuration (created in next step)
    └── my-book/
        ├── index.yaml
        └── applications/
            └── *.yaml          # YOUR spells
```

### 2. Create Book Structure

```bash
# Create book directory structure
mkdir -p bookrack/my-book/_lexicon
mkdir -p bookrack/my-book/infrastructure
mkdir -p bookrack/my-book/applications

# Create book index.yaml
cat > bookrack/my-book/index.yaml <<'EOF'
name: my-book

# Chapters define deployment order
chapters:
  - infrastructure  # Deploy infrastructure first
  - applications    # Deploy applications second

# Default trinket (workload chart)
defaultTrinket:
  repository: https://github.com/runik-spells/runik-system.git
  path: ./charts/summon
  targetRevision: main

# Trinkets register glyph types (vault, istio, certManager, etc.)
trinkets:
  kaster-vault:
    key: vault
    repository: https://github.com/runik-spells/runik-system.git
    path: ./charts/kaster
    targetRevision: main

  kaster-istio:
    key: istio
    repository: https://github.com/runik-spells/runik-system.git
    path: ./charts/kaster
    targetRevision: main

  kaster-certManager:
    key: certManager
    repository: https://github.com/runik-spells/runik-system.git
    path: ./charts/kaster
    targetRevision: main

# Appendix propagated to all chapters/spells
appendix:
  # Cluster-level configuration
  cluster:
    name: my-cluster
    environment: dev

  # Lexicon: Infrastructure registry with label-based discovery
  lexicon: []
    # Example infrastructure entries:
    # - name: external-gateway
    #   type: istio-gw
    #   labels:
    #     access: external
    #     default: book
    #   gateway: istio-system/external-gateway
    #
    # - name: letsencrypt-prod
    #   type: cert-issuer
    #   labels:
    #     default: book
    #   issuer: letsencrypt-prod
EOF
```

### 3. Create Example Spell (Application)

Create a simple nginx deployment as first spell:

```bash
# Create spell in applications chapter
cat > bookrack/my-book/applications/nginx.yaml <<'EOF'
# Simple nginx deployment using summon chart
name: nginx

# Image configuration (triggers summon chart)
image:
  name: nginx
  tag: 1.25-alpine
  pullPolicy: IfNotPresent

# Container configuration
command: []
args: []

# Ports
ports:
  - name: http
    containerPort: 80
    protocol: TCP

# Service configuration
service:
  enabled: true
  type: ClusterIP
  ports:
    - name: http
      port: 80
      targetPort: http
      protocol: TCP

# Health checks
livenessProbe:
  enabled: true
  httpGet:
    path: /
    port: http
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  enabled: true
  httpGet:
    path: /
    port: http
  initialDelaySeconds: 5
  periodSeconds: 5

# Resources
resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi

# ConfigMap with custom index.html
configMaps:
  html-content:
    location: create
    contentType: file
    name: index.html
    mountPath: /usr/share/nginx/html
    content: |
      <!DOCTYPE html>
      <html>
      <head><title>runik-system</title></head>
      <body>
        <h1>Welcome to runik-system!</h1>
        <p>This is your first spell deployed via ArgoCD and runik-system.</p>
      </body>
      </html>
EOF
```

### 4. Commit Configuration

```bash
# Stage all files
git add .

# Commit
git commit -m "Initial runik-system bookrack setup

- Add runik-system submodule
- Create my-book with infrastructure and applications chapters
- Add nginx example spell"

# Push to remote (create remote repository first on GitHub/GitLab)
# git remote add origin https://github.com/your-org/my-bookrack.git
# git push -u origin main
```

### 5. Deploy Librarian to Cluster

Librarian reads bookrack from the repository and generates ArgoCD Applications. There are two ways to deploy it:

#### Option A: Bootstrap via kubectl (Quickstart)

Use kubectl to create the initial librarian Application pointing to your repository:

```bash
# Create ArgoCD Application for librarian (bootstrap)
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: librarian-my-book
  namespace: argocd
spec:
  project: default

  source:
    repoURL: https://github.com/your-org/my-bookrack.git  # YOUR repository
    targetRevision: main
    path: vendor/runik-system/librarian  # Path to librarian chart within your repo

    helm:
      values: |
        name: my-book  # Book name to process

  destination:
    server: https://kubernetes.default.svc
    namespace: argocd

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

# Verify Application was created
kubectl get application -n argocd librarian-my-book

# Sync the Application
argocd app sync librarian-my-book
```

**How this works:**
1. ArgoCD clones YOUR repository (`https://github.com/your-org/my-bookrack.git`)
2. Navigates to `vendor/runik-system/librarian/` (the chart)
3. Helm packages the chart, following symlink `librarian/bookrack -> ../bookrack`
4. Symlink resolves to YOUR `bookrack/` directory (with your spells)
5. Librarian reads `bookrack/my-book/` and generates Applications

#### Option B: GitOps Pattern (Recommended)

Add librarian as a spell in your book's `intro` chapter:

```bash
# Create intro chapter for bootstrap spells
mkdir -p bookrack/my-book/intro

# Create librarian spell
cat > bookrack/my-book/intro/librarian.yaml <<'EOF'
# Librarian - Apps of Apps for this book
# Self-managing: librarian deploys itself and all other spells

name: librarian-my-book
repository: https://github.com/your-org/my-bookrack.git  # YOUR repository
path: vendor/runik-system/librarian
revision: main
namespace: argocd

appParams:
  disableAutoSync: false  # Enable auto-sync

values:
  name: my-book  # This book name
EOF

# Update book index.yaml to include intro chapter
cat > bookrack/my-book/index.yaml <<'EOF'
name: my-book

chapters:
  - intro           # Bootstrap chapter (contains librarian)
  - infrastructure
  - applications

# ... rest of index.yaml
EOF

# Commit and push
git add bookrack/my-book/intro/
git commit -m "Add librarian spell for GitOps self-management"
git push
```

Then bootstrap with Option A once, and librarian will manage itself from then on.

#### Option C: Local Helm Install (Development Only)

**WARNING:** This approach has limitations due to symlink resolution.

```bash
# From your bookrack repository root
cd ~/my-bookrack

# Install librarian chart locally
helm install librarian ./vendor/runik-system/librarian \
  --namespace argocd \
  --set name=my-book \
  --create-namespace

# PROBLEM: The symlink vendor/runik-system/librarian/bookrack -> ../bookrack
# points to vendor/bookrack (doesn't exist) instead of ../../bookrack (your bookrack)
```

**To fix symlink for local development:**
```bash
# Temporary fix: Copy librarian chart and fix symlink
cp -r vendor/runik-system/librarian /tmp/librarian-local
cd /tmp/librarian-local
rm bookrack
ln -s ~/my-bookrack/bookrack bookrack

# Now install from fixed copy
helm install librarian /tmp/librarian-local \
  --namespace argocd \
  --set name=my-book
```

**Recommendation:** Use Option A or B for production. Option C is only for local testing.

### 6. Verify ArgoCD Applications

```bash
# Check ArgoCD Applications created by librarian
kubectl get applications -n argocd

# Expected output:
# NAME                        SYNC STATUS   HEALTH STATUS
# my-book-applications-nginx  Synced        Healthy

# View application details
argocd app get my-book-applications-nginx

# List all applications
argocd app list
```

### 7. How Librarian Works (Technical Deep Dive)

Understanding librarian's internal mechanisms helps debug issues and optimize your bookrack structure.

#### Two-Pass Processing System

Librarian uses a **two-pass architecture** to consolidate configuration and generate ArgoCD Applications:

**PASS 1: Consolidate Appendix** (Configuration Collection)
```
1. Read book index.yaml → book.appendix
2. For each chapter:
   - Read chapter/index.yaml → merge chapter.appendix
   - For each spell in chapter:
     - Read spell.yaml → merge spell.appendix
3. Result: $globalAppendix (consolidated configuration)
```

**PASS 2: Generate Applications** (ArgoCD Resource Creation)
```
For each chapter:
  For each spell:
    1. Detect needed trinkets (vault, istio, tarot, etc.)
    2. Build final appendix: global < chapterLocal < fileLocal
    3. Generate ArgoCD Application with:
       - Source 1: defaultTrinket (summon) or custom chart
       - Sources 2..N: Detected trinkets (kaster, tarot, etc.)
       - Values: spell + globalAppendix + lexicon + cards
    4. Apply sync policies and destination
```

**Why two passes?**
- **Pass 1** ensures all configuration is available before generating any Application
- **Pass 2** can make decisions based on complete context (e.g., trinket detection, cluster selection)

#### Multi-Source Detection

Each spell generates an ArgoCD Application with **multiple sources** automatically:

**Source 1 (Primary - Always Present):**
- **If spell has `chart:` or `path:`** → uses that custom chart
- **Otherwise** → uses `defaultTrinket` (typically summon)

**Sources 2..N (Trinkets - Dynamically Detected):**

Librarian scans each spell for registered trinket keys and adds sources automatically:

```yaml
# spell.yaml
name: my-app

image:
  name: nginx
  tag: "1.25"

vault:              # ← Librarian detects this key
  my-secret:
    path: secret/data/app

istio:              # ← And this key
  my-vs:
    hosts: [app.example.com]
```

**Generated Application has 3 sources:**
1. **summon** (workload) - Deployment, Service, etc.
2. **kaster** (vault glyph) - VaultSecret resource
3. **kaster** (istio glyph) - VirtualService resource

**How trinket detection works:**
1. Book `index.yaml` registers trinkets with keys:
   ```yaml
   trinkets:
     kaster-vault:
       key: vault        # Detection key
       path: ./charts/kaster
   ```
2. Librarian checks if spell has `vault:` key
3. If found, adds kaster source with only vault data
4. Kaster chart receives `values.vault:` and renders VaultSecret

#### Configuration Hierarchy

Configuration merges in specific order (later overrides earlier):

**defaultTrinket (workload chart):**
```
book.defaultTrinket < chapter.defaultTrinket
```

**trinkets (glyph registrations):**
```
book.trinkets < chapter.trinkets
```

**appendix (shared configuration):**
```
book.appendix < chapter.appendix < spell.appendix
```

**localAppendix (override mechanism):**
```
chapter.localAppendix < spell.localAppendix
```
- Overrides globalAppendix for specific scopes
- Useful for chapter/spell-specific infrastructure

**appParams (ArgoCD sync policies):**
```
book.appParams < chapter.appParams < spell.appParams
```

**Example hierarchy:**
```yaml
# book/index.yaml
appendix:
  cluster:
    environment: production    # ← Base value

# book/staging/index.yaml
localAppendix:
  cluster:
    environment: staging       # ← Chapter override

# book/staging/api.yaml
localAppendix:
  cluster:
    name: staging-us-west      # ← Spell override

# Final values for staging/api spell:
cluster:
  environment: staging         # From chapter
  name: staging-us-west        # From spell
```

#### Lexicon System

Librarian processes and distributes lexicon (infrastructure registry) to all charts:

**Input (book appendix):**
```yaml
appendix:
  lexicon:
    - name: vault-prod
      type: vault
      labels:
        default: book
        environment: production
      address: https://vault.vault.svc:8200

    - name: external-gateway
      type: istio-gw
      labels:
        access: external
        default: book
      gateway: istio-system/external-gateway
```

**Processing:**
1. Librarian consolidates lexicon from book + chapters + spells
2. Ensures each entry has a `.name` field
3. Converts to dictionary keyed by name

**Distribution:**
```yaml
# Passed to ALL sources (summon, kaster, tarot, runes)
values:
  lexicon:
    vault-prod:
      name: vault-prod
      type: vault
      labels: {...}
      address: https://vault...
    external-gateway:
      name: external-gateway
      type: istio-gw
      ...
```

**Usage in charts:**
- Charts use `runicIndexer` to query lexicon with label selectors
- Example: Istio glyph searches `type: istio-gw` + `access: external`
- Returns matching infrastructure configuration

#### Values Passed to Charts

**To defaultTrinket (summon):**
```yaml
# Spell definition (cleaned)
name: my-app
image:
  name: nginx
  tag: "1.25"
ports: [...]
service: {...}
# (vault:, istio:, runes:, appParams: removed)

# Book context
spellbook:
  name: my-book
  chapters: [...]
  # (appParams, summon, kaster, appendix removed)

# Chapter context
chapter:
  name: applications

# Infrastructure
lexicon: {...}
cards: {...}      # Tarot cards if present
```

**To trinkets (kaster, tarot, etc.):**
```yaml
# ONLY the trinket key data
vault:
  my-secret:
    path: secret/data/app

# Same book context
spellbook: {...}
chapter: {...}
lexicon: {...}
cards: {...}     # Only for tarot trinket
```

**To runes (additional charts):**
```yaml
# Rune values
values: {...}

# Same book context
spellbook: {...}
chapter: {...}
lexicon: {...}
cards: {...}
```

#### Cluster Selection via Runic Indexer

Librarian uses runicIndexer for dynamic cluster selection:

**Spell with cluster selector:**
```yaml
name: my-app

image:
  name: nginx
  tag: "1.25"

clusterSelector:
  labels:
    region: us-west
    environment: production
```

**Lexicon with clusters:**
```yaml
appendix:
  lexicon:
    - name: prod-us-west
      type: k8s-cluster
      labels:
        region: us-west
        environment: production
      clusterURL: https://k8s-prod-usw.example.com
```

**Librarian process:**
1. Detects `clusterSelector` in spell
2. Queries lexicon: `type: k8s-cluster` + spell labels
3. Finds matching cluster(s)
4. Sets Application `destination.server` to matched clusterURL

**Hierarchy:** `book.clusterSelector < chapter.clusterSelector < spell.clusterSelector`

#### Sync Policies Configuration

Sync policies cascade through hierarchy:

**Default (librarian values.yaml):**
```yaml
appParams:
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 2
```

**Override in book:**
```yaml
# book/index.yaml
appParams:
  disableAutoSync: true    # Disable auto-sync for entire book
```

**Override in spell:**
```yaml
# spell.yaml
appParams:
  syncPolicy:
    automated:
      prune: false         # Keep resources on deletion
  customFinalizers:
    - resources-finalizer.argocd.argoproj.io/background
```

#### Debugging Librarian

**View generated Application:**
```bash
# Get Application manifest
kubectl get application -n argocd my-book-applications-nginx -o yaml

# Check sources
kubectl get application -n argocd my-book-applications-nginx \
  -o jsonpath='{.spec.sources}' | jq

# View values passed to charts
kubectl get application -n argocd my-book-applications-nginx \
  -o jsonpath='{.spec.sources[0].helm.values}'
```

**Common debugging scenarios:**

**Missing trinket source?**
```bash
# Check trinkets registered in book
cat bookrack/my-book/index.yaml | grep -A 10 trinkets

# Verify spell has the trinket key
cat bookrack/my-book/applications/api.yaml | grep -E "vault:|istio:|tarot:"
```

**Appendix not merging correctly?**
```bash
# View final appendix in Application values
kubectl get application -n argocd my-book-applications-nginx \
  -o jsonpath='{.spec.sources[0].helm.values}' | yq .lexicon
```

**Cluster selection not working?**
```bash
# Check clusterSelector and lexicon
kubectl get application -n argocd my-book-applications-nginx \
  -o jsonpath='{.spec.destination.server}'

# Should match lexicon entry clusterURL
```

#### Architecture Summary

```
┌─────────────────────────────────────────────────────────┐
│ LIBRARIAN INTERNAL FLOW                                 │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  1. READ BOOKRACK STRUCTURE                             │
│     bookrack/my-book/index.yaml                         │
│     bookrack/my-book/applications/*.yaml                │
│                                                          │
│  2. PASS 1: CONSOLIDATE APPENDIX                        │
│     book.appendix                                        │
│       → chapter.appendix (merge)                         │
│         → spell.appendix (merge)                         │
│           → $globalAppendix                              │
│                                                          │
│  3. PASS 2: GENERATE APPLICATIONS                       │
│     For each spell:                                      │
│       ├─ Detect trinkets (vault, istio, tarot, etc.)    │
│       ├─ Build final appendix (global + local)          │
│       ├─ Generate multi-source spec:                    │
│       │   ├─ Source 1: defaultTrinket or custom chart   │
│       │   └─ Sources 2..N: Detected trinkets            │
│       ├─ Apply sync policies (book < chapter < spell)   │
│       └─ Select cluster via runicIndexer                │
│                                                          │
│  4. OUTPUT: ArgoCD Applications                         │
│     apiVersion: argoproj.io/v1alpha1                    │
│     kind: Application                                    │
│     spec:                                                │
│       sources: [summon, kaster, ...]                    │
│       destination: {server, namespace}                  │
│       syncPolicy: {automated, retry}                    │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

**Key insights:**
- **Two-pass** ensures complete context before generation
- **Multi-source** enables modular glyph composition
- **Trinket detection** happens automatically via registered keys
- **Configuration hierarchy** allows flexible overrides
- **Lexicon** provides dynamic infrastructure discovery
- **Runic indexer** enables label-based matching

This architecture enables the declarative, composable, GitOps workflow that runik-system provides.

## First Deployment

### 1. Sync Applications via ArgoCD

**Via UI:**
1. Navigate to ArgoCD UI (http://argocd.local or https://localhost:8080)
2. Login with admin credentials
3. Find application: `my-book-applications-nginx`
4. Click "Sync" → "Synchronize"
5. Monitor deployment progress

**Via CLI:**
```bash
# Sync specific application
argocd app sync my-book-applications-nginx

# Sync all applications
argocd app sync -l argocd.argoproj.io/instance=my-book

# Watch sync progress
argocd app wait my-book-applications-nginx --health
```

**Via kubectl (GitOps way):**
```bash
# Enable auto-sync on application
kubectl patch application my-book-applications-nginx -n argocd \
  --type merge \
  --patch '{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}'
```

### 2. Verify Deployment

```bash
# Check pods
kubectl get pods -n my-book-applications

# Expected: nginx pod Running
# NAME                     READY   STATUS    RESTARTS   AGE
# nginx-xxxxxxxxxx-xxxxx   1/1     Running   0          30s

# Check service
kubectl get service -n my-book-applications

# Check all resources
kubectl get all -n my-book-applications
```

### 3. Test Application

```bash
# Port-forward to nginx service
kubectl port-forward -n my-book-applications svc/nginx 8081:80

# Test in browser: http://localhost:8081
# Or via curl:
curl http://localhost:8081

# Expected output:
# <!DOCTYPE html>
# <html>
# <head><title>runik-system</title></head>
# ...
```

### 4. View Logs

```bash
# Get nginx logs
kubectl logs -n my-book-applications deployment/nginx

# Follow logs
kubectl logs -n my-book-applications deployment/nginx -f

# View events
kubectl get events -n my-book-applications --sort-by='.lastTimestamp'
```

### 5. Make Changes (GitOps Workflow)

Edit spell and watch ArgoCD auto-sync:

```bash
# Edit nginx spell
cat > bookrack/my-book/applications/nginx.yaml <<'EOF'
name: nginx

image:
  name: nginx
  tag: 1.25-alpine
  pullPolicy: IfNotPresent

replicas: 2  # Scale to 2 replicas

ports:
  - name: http
    containerPort: 80

service:
  enabled: true
  type: ClusterIP
  ports:
    - name: http
      port: 80
      targetPort: http

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi
EOF

# Commit and push
git add bookrack/my-book/applications/nginx.yaml
git commit -m "Scale nginx to 2 replicas"
git push

# Watch ArgoCD detect change and sync
argocd app get my-book-applications-nginx --refresh

# Watch pods scale
kubectl get pods -n my-book-applications -w
```

## Troubleshooting

Having issues? Check the comprehensive troubleshooting guide:

**→ [Bootstrapping Troubleshooting Guide](BOOTSTRAPPING_TROUBLESHOOTING.md)**

Common topics covered:
- ArgoCD installation issues
- Librarian configuration problems
- Spell deployment failures
- Helm errors
- Debugging commands reference

## Next Steps

### 1. Add More Glyphs

Enhance your spells with infrastructure glyphs:

#### Vault Integration (Secrets Management)

```yaml
# bookrack/my-book/applications/api.yaml
name: api

image:
  repository: myorg/api
  tag: v1.0
  pullPolicy: IfNotPresent

service:
  enabled: true

# Add Vault secret (direct type for summon)
vault:
  db-credentials:
    path: secret/data/production/database
    outputType: secret
```

#### Istio Integration (Service Mesh)

```yaml
# bookrack/my-book/applications/frontend.yaml
name: frontend

image:
  repository: myorg/frontend
  tag: v1.0
  pullPolicy: IfNotPresent

service:
  enabled: true

# Add Istio VirtualService (direct type for summon)
istio:
  frontend-vs:
    selector:
      access: external
    hosts:
      - frontend.example.com
    routes:
      - destination:
          host: frontend
          port: 80
```

#### cert-manager Integration (TLS Certificates)

```yaml
# bookrack/my-book/infrastructure/tls-cert.yaml
name: app-tls-cert

# Pure infrastructure (no image/chart = kaster only)
certManager:
  app-cert:
    dnsNames:
      - app.example.com
      - www.app.example.com
    selector:
      default: book  # Matches issuer in lexicon
```

**Update lexicon in book index.yaml:**
```yaml
appendix:
  lexicon:
    - name: letsencrypt-prod
      type: cert-issuer
      labels:
        default: book
      issuer: letsencrypt-prod
```

### 2. Setup Lexicon for Infrastructure Discovery

Add infrastructure entries to enable dynamic discovery:

```yaml
# bookrack/my-book/index.yaml
appendix:
  lexicon:
    # Istio Gateway
    - name: external-gateway
      type: istio-gw
      labels:
        access: external
        default: book
      gateway: istio-system/external-gateway

    # Cert Issuer
    - name: letsencrypt-prod
      type: cert-issuer
      labels:
        default: book
      issuer: letsencrypt-prod

    # Database
    - name: postgres-prod
      type: database
      labels:
        environment: production
        default: book
      host: postgres.database.svc.cluster.local
      port: 5432

    # Vault Instance
    - name: vault-prod
      type: vault
      labels:
        default: book
      address: https://vault.vault.svc.cluster.local:8200
```

### 3. Enable Auto-Sync for GitOps

Configure ArgoCD to automatically sync on git changes:

```bash
# Enable auto-sync for all applications in book
argocd app set -l argocd.argoproj.io/instance=my-book \
  --sync-policy automated \
  --auto-prune \
  --self-heal

# Or edit application manually
kubectl patch application my-book-applications-nginx -n argocd \
  --type merge \
  --patch '
spec:
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true'
```

### 4. Add Webhook for Fast Sync

Configure webhook for instant synchronization:

```bash
# Get webhook URL
echo "https://$(kubectl get ingress -n argocd argocd-server -o jsonpath='{.spec.rules[0].host}')/api/webhook"

# Configure in your git provider (GitHub, GitLab, etc.):
# URL: https://argocd.example.com/api/webhook
# Content type: application/json
# Events: push, pull_request
```

### 5. Multi-Environment Setup

Create separate books for different environments:

```bash
# Create development book
mkdir -p bookrack/my-book-dev/{infrastructure,applications}
cp bookrack/my-book/index.yaml bookrack/my-book-dev/

# Create production book
mkdir -p bookrack/my-book-prod/{infrastructure,applications}
cp bookrack/my-book/index.yaml bookrack/my-book-prod/

# Update cluster names in each book
sed -i 's/my-cluster/my-cluster-dev/' bookrack/my-book-dev/index.yaml
sed -i 's/my-cluster/my-cluster-prod/' bookrack/my-book-prod/index.yaml

# Deploy both books
helm upgrade librarian ./vendor/runik-system/librarian \
  --namespace argocd \
  --reuse-values \
  --set bookrack.books[0]="my-book-dev" \
  --set bookrack.books[1]="my-book-prod"
```

### 6. Implement Progressive Delivery

Use Argo Rollouts for canary and blue-green deployments:

```bash
# Install Argo Rollouts
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# Add rollout strategy to spell
cat > bookrack/my-book/applications/api-rollout.yaml <<'EOF'
name: api

image:
  repository: myorg/api
  tag: v1.0
  pullPolicy: IfNotPresent

workloadType: rollout  # Use rollout instead of deployment

strategy:
  canary:
    steps:
      - setWeight: 20
      - pause: {duration: 1m}
      - setWeight: 40
      - pause: {duration: 1m}
      - setWeight: 60
      - pause: {duration: 1m}
      - setWeight: 80
      - pause: {duration: 1m}

service:
  enabled: true
EOF
```

### 7. Monitoring and Observability

Add Prometheus metrics and Grafana dashboards:

```bash
# Install kube-prometheus-stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

# Add ServiceMonitor for applications
cat > bookrack/my-book/infrastructure/service-monitor.yaml <<'EOF'
name: app-metrics

apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: app-metrics
spec:
  selector:
    matchLabels:
      app: api
  endpoints:
    - port: metrics
      interval: 30s
EOF
```

### 8. Security Hardening

#### Add NetworkPolicies
```yaml
# bookrack/my-book/infrastructure/network-policy.yaml
name: default-deny

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
```

#### Add PodSecurityPolicies
```yaml
# In spell configuration
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  capabilities:
    drop:
      - ALL
  readOnlyRootFilesystem: true
```

### 9. Backup and Disaster Recovery

```bash
# Backup ArgoCD configuration
argocd admin export > argocd-backup.yaml

# Backup applications
kubectl get applications -n argocd -o yaml > applications-backup.yaml

# Schedule regular backups with Velero
helm install velero vmware-tanzu/velero \
  --namespace velero \
  --create-namespace \
  --set configuration.backupStorageLocation[0].bucket=argocd-backups
```

### 10. Learn More

**Documentation:**
- [ArgoCD Official Docs](https://argo-cd.readthedocs.io/)
- [runik-system docs/](../docs/)
- [GETTING_STARTED.md](./GETTING_STARTED.md) - Detailed bookrack usage
- [LIBRARIAN.md](./LIBRARIAN.md) - Apps of Apps pattern
- [SUMMON.md](./SUMMON.md) - Workload chart reference
- [GLYPHS.md](./GLYPHS.md) - Available glyphs

**Testing:**
```bash
# TDD workflow
cd vendor/runik-system
make test              # Run comprehensive tests
make test-status       # Check test coverage
make list-glyphs       # List available glyphs
```

**Community:**
- GitHub Issues: https://github.com/runik-spells/runik-system/issues
- Documentation: https://docs.runik.ing

---

**Congratulations!** 🎉 You now have a fully functional GitOps workflow with ArgoCD and runik-system.

Your next commit to the bookrack repository will automatically trigger a deployment.

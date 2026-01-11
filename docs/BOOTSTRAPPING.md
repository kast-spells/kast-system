# Bootstrapping Guide

Complete guide for bootstrapping a Kubernetes cluster with ArgoCD and kast-system from scratch.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [ArgoCD Installation](#argocd-installation)
4. [kast-system Setup](#kast-system-setup)
5. [First Deployment](#first-deployment)
6. [Troubleshooting](#troubleshooting)
7. [Next Steps](#next-steps)

## Overview

This guide walks you through setting up a complete GitOps workflow using:
- **Kubernetes cluster** (any distribution: kind, k3s, EKS, GKE, AKS, on-prem)
- **ArgoCD** (from official Helm chart)
- **kast-system** (TDD Kubernetes deployment framework)

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

**Example spell reference:** Check the example ArgoCD spell at [bookrack/the-example-book/intro/argocd.yaml](https://github.com/kast-spells/kast-system/blob/master/bookrack/the-example-book/intro/argocd.yaml)

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

## kast-system Setup

### 1. Create Your Bookrack Repository from Template

The easiest way to get started is using the official bookrack template repository. This provides a production-ready structure with example spells, automated setup, and all necessary configurations.

#### Option A: Use GitHub Template (Recommended)

**Step 1: Create repository from template**

1. Navigate to the template: https://github.com/kast-spells/bookrack-template
2. Click **"Use this template"** → **"Create a new repository"**
3. Configure your repository:
   - **Owner**: Your GitHub username or organization
   - **Repository name**: `my-bookrack` (or your preferred name)
   - **Visibility**: Public or Private
   - **Description** (optional): "Kubernetes GitOps configuration using kast-system"
4. Click **"Create repository"**

**Step 2: Clone your new repository**

```bash
# Clone your repository
git clone https://github.com/YOUR-ORG/my-bookrack.git
cd my-bookrack

# Initialize kast-system submodule
git submodule update --init --recursive
```

**What you just created:**
```
my-bookrack/                         # YOUR repository
├── vendor/
│   └── kast-system/                 # Submodule (library)
│       ├── charts/
│       │   ├── glyphs/              # Glyph templates
│       │   ├── kaster/              # Glyph orchestrator
│       │   └── summon/              # Workload chart
│       └── librarian/               # ArgoCD Apps of Apps
│           └── bookrack -> ../bookrack
├── bookrack/
│   └── example-book/                # Example book (rename in next step)
│       ├── index.yaml               # Book configuration
│       ├── infrastructure/
│       │   ├── index.yaml           # Chapter config
│       │   └── redis.yaml           # Example infrastructure spell
│       └── applications/
│           ├── index.yaml           # Chapter config
│           ├── nginx-example.yaml   # Basic spell
│           ├── app-with-secrets.yaml  # Vault integration example
│           └── app-with-istio.yaml    # Istio integration example
├── setup.sh                         # Automated setup script
├── Makefile                         # Helper commands
└── README.md                        # Template documentation
```

#### Option B: Manual Clone (Alternative)

If you prefer not to use GitHub's template feature:

```bash
# Clone the template directly
git clone https://github.com/kast-spells/bookrack-template.git my-bookrack
cd my-bookrack

# Remove original git history and reinitialize
rm -rf .git
git init

# Initialize kast-system submodule
git submodule add https://github.com/kast-spells/kast-system.git vendor/kast-system
git submodule update --init --recursive

# Initial commit
git add .
git commit -m "Initial bookrack setup from template"

# Connect to your remote repository
git remote add origin https://github.com/YOUR-ORG/my-bookrack.git
git push -u origin main
```

### 2. Run Automated Setup Script

The template includes an interactive setup script that configures your book with your cluster details:

```bash
# Run the setup script
./setup.sh
```

**The script will prompt you for:**

| Prompt | Default | Description |
|--------|---------|-------------|
| **Book name** | `my-book` | Name for your book (becomes directory name) |
| **Cluster name** | `my-cluster` | Kubernetes cluster identifier |
| **Environment** | `dev` | Environment type: `dev`, `staging`, or `prod` |
| **Git repository URL** | (required) | Your repository URL for ArgoCD |

**Example interaction:**
```
Enter book name [my-book]: production-apps
Enter cluster name [my-cluster]: prod-us-east-1
Enter environment (dev/staging/prod) [dev]: prod
Enter git repository URL: https://github.com/your-org/my-bookrack.git

Configuration:
  Book name: production-apps
  Cluster name: prod-us-east-1
  Environment: prod
  Git repository: https://github.com/your-org/my-bookrack.git

Proceed with setup? (y/n): y
```

**What the script does:**

1. **Initializes submodule**: Adds kast-system if not already present
2. **Renames example-book**: Renames `bookrack/example-book/` to your book name
3. **Updates configuration**: Sets cluster name and environment in `index.yaml`
4. **Commits changes**: Creates git commit with your configuration
5. **Deploys librarian** (optional): Can automatically create ArgoCD Application

**After setup, your structure looks like:**
```
my-bookrack/
└── bookrack/
    └── production-apps/              # Your book name
        ├── index.yaml                # Updated with your cluster/env
        ├── infrastructure/
        │   ├── index.yaml
        │   └── redis.yaml
        └── applications/
            ├── index.yaml
            ├── nginx-example.yaml
            ├── app-with-secrets.yaml
            └── app-with-istio.yaml
```

### 3. (Optional) Customize Your Book

After running `setup.sh`, you may want to customize the generated configuration:

#### Review and Edit Book Configuration

```bash
# Edit book-level configuration
vim bookrack/YOUR-BOOK-NAME/index.yaml
```

**Key sections to review:**

```yaml
name: YOUR-BOOK-NAME

chapters:
  - infrastructure  # Deploys first
  - applications    # Deploys second
  # Add more chapters as needed

appendix:
  cluster:
    name: YOUR-CLUSTER-NAME
    environment: prod  # or dev/staging
    region: us-east-1  # Add your region

  lexicon:
    # Add infrastructure registry entries
    - name: external-gateway
      type: istio-gw
      labels:
        access: external
        default: book
      gateway: istio-system/external-gateway
```

#### Explore Example Spells

The template includes production-ready examples:

**Basic workload** (`nginx-example.yaml`):
```bash
cat bookrack/YOUR-BOOK-NAME/applications/nginx-example.yaml
```

**Vault integration** (`app-with-secrets.yaml`):
```bash
cat bookrack/YOUR-BOOK-NAME/applications/app-with-secrets.yaml
# Shows: vault secret injection, environment variable binding
```

**Istio integration** (`app-with-istio.yaml`):
```bash
cat bookrack/YOUR-BOOK-NAME/applications/app-with-istio.yaml
# Shows: VirtualService, service mesh configuration
```

**Infrastructure** (`redis.yaml`):
```bash
cat bookrack/YOUR-BOOK-NAME/infrastructure/redis.yaml
# Shows: StatefulSet, persistent volumes
```

#### Add Your Own Spells

```bash
# Create new spell
cat > bookrack/YOUR-BOOK-NAME/applications/my-api.yaml <<'EOF'
name: my-api

replicas: 2

image:
  repository: myorg/api
  tag: "v1.0.0"
  pullPolicy: IfNotPresent

service:
  enabled: true
  type: ClusterIP
  ports:
    - name: http
      port: 8080
      targetPort: http

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi
EOF
```

### 4. Commit and Push Configuration

```bash
# Stage all your customizations
git add bookrack/

# Commit changes
git commit -m "Customize book configuration

- Update lexicon with infrastructure
- Add custom application spells
- Configure production settings"

# Push to remote
git push origin main
```

### 5. Deploy Librarian to Cluster

Librarian reads bookrack from the repository and generates ArgoCD Applications.

**Note:** If you ran `setup.sh` in the previous step and chose to deploy the librarian automatically, you can skip this section and proceed to [Verify ArgoCD Applications](#6-verify-argocd-applications).

There are two GitOps ways to deploy librarian:

#### Option A: Via setup.sh (Automated - Recommended)

If you haven't already, the `setup.sh` script can deploy librarian for you:

```bash
# Run setup.sh if not done already
./setup.sh

# When prompted "Deploy librarian to ArgoCD? (y/n):", choose 'y'
```

The script will automatically create the ArgoCD Application with your configuration.

**How this works:**
1. Script creates an ArgoCD Application manifest
2. ArgoCD clones YOUR repository (`https://github.com/your-org/my-bookrack.git`)
3. Navigates to `vendor/kast-system/librarian/` (the chart from submodule)
4. Helm packages the chart, following symlink `librarian/bookrack -> ../bookrack`
5. Symlink resolves to YOUR `bookrack/` directory (with your spells)
6. Librarian reads `bookrack/YOUR-BOOK-NAME/` and generates Applications

#### Option B: GitOps Pattern (Self-Managing)

Add librarian as a spell in your book's `intro` chapter:

```bash
# Create intro chapter for bootstrap spells
mkdir -p bookrack/YOUR-BOOK-NAME/intro

# Create librarian spell
cat > bookrack/YOUR-BOOK-NAME/intro/librarian.yaml <<'EOF'
# Librarian - Apps of Apps for this book
# Self-managing: librarian deploys itself and all other spells

name: librarian-YOUR-BOOK-NAME
repository: https://github.com/your-org/my-bookrack.git  # YOUR repository
path: vendor/kast-system/librarian
revision: main
namespace: argocd

appParams:
  disableAutoSync: false  # Enable auto-sync

values:
  name: YOUR-BOOK-NAME  # This book name
EOF

# Update book index.yaml to include intro chapter
# Edit your book's index.yaml to add 'intro' to chapters list:
vim bookrack/YOUR-BOOK-NAME/index.yaml
# Add 'intro' as first chapter:
#   chapters:
#     - intro           # Bootstrap chapter (contains librarian)
#     - infrastructure
#     - applications

# Commit and push
git add bookrack/YOUR-BOOK-NAME/intro/
git commit -m "Add librarian spell for GitOps self-management"
git push
```

Then bootstrap with Option A once, and librarian will manage itself from then on.

**Why this is GitOps:**
- Librarian configuration lives in Git (your bookrack repository)
- Changes to spells trigger automatic deployments
- Self-healing: librarian will recreate itself if deleted
- Auditable: all changes tracked in Git history

### 6. Verify ArgoCD Applications

```bash
# Check ArgoCD Applications created by librarian
kubectl get applications -n argocd

# Expected output (using default template examples):
# NAME                                    SYNC STATUS   HEALTH STATUS
# YOUR-BOOK-NAME-applications-nginx-example    Synced        Healthy
# YOUR-BOOK-NAME-applications-app-with-secrets OutOfSync     Healthy
# YOUR-BOOK-NAME-applications-app-with-istio   Synced        Healthy
# YOUR-BOOK-NAME-infrastructure-redis          Synced        Healthy

# View specific application details
argocd app get YOUR-BOOK-NAME-applications-nginx-example

# List all applications for your book
argocd app list -l book=YOUR-BOOK-NAME
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
kubectl get application -n argocd YOUR-BOOK-NAME-applications-nginx-example -o yaml

# Check sources
kubectl get application -n argocd YOUR-BOOK-NAME-applications-nginx-example \
  -o jsonpath='{.spec.sources}' | jq

# View values passed to charts
kubectl get application -n argocd YOUR-BOOK-NAME-applications-nginx-example \
  -o jsonpath='{.spec.sources[0].helm.values}'
```

**Common debugging scenarios:**

**Missing trinket source?**
```bash
# Check trinkets registered in book
cat bookrack/YOUR-BOOK-NAME/index.yaml | grep -A 10 trinkets

# Verify spell has the trinket key
cat bookrack/YOUR-BOOK-NAME/applications/api.yaml | grep -E "vault:|istio:|tarot:"
```

**Appendix not merging correctly?**
```bash
# View final appendix in Application values
kubectl get application -n argocd YOUR-BOOK-NAME-applications-nginx-example \
  -o jsonpath='{.spec.sources[0].helm.values}' | yq .lexicon
```

**Cluster selection not working?**
```bash
# Check clusterSelector and lexicon
kubectl get application -n argocd YOUR-BOOK-NAME-applications-nginx-example \
  -o jsonpath='{.spec.destination.server}'

# Should match lexicon entry clusterURL
```

#### Architecture Summary

```
┌─────────────────────────────────────────────────────────┐
│ LIBRARIAN INTERNAL FLOW                                 │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. READ BOOKRACK STRUCTURE                             │
│     bookrack/YOUR-BOOK-NAME/index.yaml                         │
│     bookrack/YOUR-BOOK-NAME/applications/*.yaml                │
│                                                         │
│  2. PASS 1: CONSOLIDATE APPENDIX                        │
│     book.appendix                                       │
│       → chapter.appendix (merge)                        │
│         → spell.appendix (merge)                        │
│           → $globalAppendix                             │
│                                                         │
│  3. PASS 2: GENERATE APPLICATIONS                       │
│     For each spell:                                     │
│       ├─ Detect trinkets (vault, istio, tarot, etc.)    │
│       ├─ Build final appendix (global + local)          │
│       ├─ Generate multi-source spec:                    │
│       │   ├─ Source 1: defaultTrinket or custom chart   │
│       │   └─ Sources 2..N: Detected trinkets            │
│       ├─ Apply sync policies (book < chapter < spell)   │
│       └─ Select cluster via runicIndexer                │
│                                                         │
│  4. OUTPUT: ArgoCD Applications                         │
│     apiVersion: argoproj.io/v1alpha1                    │
│     kind: Application                                   │
│     spec:                                               │
│       sources: [summon, kaster, ...]                    │
│       destination: {server, namespace}                  │
│       syncPolicy: {automated, retry}                    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Key insights:**
- **Two-pass** ensures complete context before generation
- **Multi-source** enables modular glyph composition
- **Trinket detection** happens automatically via registered keys
- **Configuration hierarchy** allows flexible overrides
- **Lexicon** provides dynamic infrastructure discovery
- **Runic indexer** enables label-based matching

This architecture enables the declarative, composable, GitOps workflow that kast-system provides.

## First Deployment

### 1. Sync Applications via ArgoCD

**Via UI:**
1. Navigate to ArgoCD UI (http://argocd.local or https://localhost:8080)
2. Login with admin credentials
3. Find application: `YOUR-BOOK-NAME-applications-nginx-example`
4. Click "Sync" → "Synchronize"
5. Monitor deployment progress

**Via CLI:**
```bash
# Sync specific application
argocd app sync YOUR-BOOK-NAME-applications-nginx-example

# Sync all applications for your book
argocd app sync -l book=YOUR-BOOK-NAME

# Watch sync progress
argocd app wait YOUR-BOOK-NAME-applications-nginx-example --health
```

**Via kubectl (GitOps way):**
```bash
# Enable auto-sync on application (if not already enabled)
kubectl patch application YOUR-BOOK-NAME-applications-nginx-example -n argocd \
  --type merge \
  --patch '{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}'
```

### 2. Verify Deployment

```bash
# Check pods in applications chapter namespace
kubectl get pods -n YOUR-BOOK-NAME-applications

# Expected: nginx-example pod Running
# NAME                             READY   STATUS    RESTARTS   AGE
# nginx-example-xxxxxxxxxx-xxxxx   1/1     Running   0          30s

# Check service
kubectl get service -n YOUR-BOOK-NAME-applications

# Check all resources
kubectl get all -n YOUR-BOOK-NAME-applications
```

### 3. Test Application

```bash
# Port-forward to nginx-example service
kubectl port-forward -n YOUR-BOOK-NAME-applications svc/nginx-example 8081:80

# Test in browser: http://localhost:8081
# Or via curl:
curl http://localhost:8081

# Expected output:
# Default nginx welcome page
```

### 4. View Logs

```bash
# Get nginx-example logs
kubectl logs -n YOUR-BOOK-NAME-applications deployment/nginx-example

# Follow logs
kubectl logs -n YOUR-BOOK-NAME-applications deployment/nginx-example -f

# View events
kubectl get events -n YOUR-BOOK-NAME-applications --sort-by='.lastTimestamp'
```

### 5. Make Changes (GitOps Workflow)

Edit a spell and watch ArgoCD automatically sync the changes:

```bash
# Edit nginx-example spell to scale replicas
vim bookrack/YOUR-BOOK-NAME/applications/nginx-example.yaml

# Change replicas from 2 to 3:
# replicas: 3

# Or use sed to make the change
sed -i 's/replicas: 2/replicas: 3/' bookrack/YOUR-BOOK-NAME/applications/nginx-example.yaml

# Commit and push
git add bookrack/YOUR-BOOK-NAME/applications/nginx-example.yaml
git commit -m "Scale nginx-example to 3 replicas"
git push

# Watch ArgoCD detect change and sync (if auto-sync enabled)
argocd app get YOUR-BOOK-NAME-applications-nginx-example --refresh

# Watch pods scale
kubectl get pods -n YOUR-BOOK-NAME-applications -w
# You should see a third pod being created
```

**GitOps in action:**
1. You commit changes to Git (source of truth)
2. ArgoCD detects the change (webhook or polling)
3. ArgoCD automatically syncs the cluster state
4. Kubernetes creates the new pod
5. All changes are auditable in Git history

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
# bookrack/YOUR-BOOK-NAME/applications/api.yaml
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
# bookrack/YOUR-BOOK-NAME/applications/frontend.yaml
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
# bookrack/YOUR-BOOK-NAME/infrastructure/tls-cert.yaml
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
# bookrack/YOUR-BOOK-NAME/index.yaml
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

**Option A: Multiple Books (Recommended for isolated environments)**

```bash
# Clone your existing bookrack repository for each environment
# or use the template multiple times

# Development environment
git clone https://github.com/kast-spells/bookrack-template.git dev-bookrack
cd dev-bookrack
./setup.sh
# Enter: book name = "app-dev", cluster = "cluster-dev", env = "dev"

# Production environment
git clone https://github.com/kast-spells/bookrack-template.git prod-bookrack
cd prod-bookrack
./setup.sh
# Enter: book name = "app-prod", cluster = "cluster-prod", env = "prod"
```

**Option B: Chapters per Environment (Single book)**

```bash
# Within your existing book, use chapters for environments
mkdir -p bookrack/YOUR-BOOK-NAME/{dev,staging,prod}

# Each chapter has its own index.yaml with environment-specific config
cat > bookrack/YOUR-BOOK-NAME/dev/index.yaml <<'EOF'
localAppendix:
  cluster:
    environment: dev
    name: cluster-dev
EOF

# Copy spells to each environment chapter
cp -r bookrack/YOUR-BOOK-NAME/applications/* bookrack/YOUR-BOOK-NAME/dev/
cp -r bookrack/YOUR-BOOK-NAME/applications/* bookrack/YOUR-BOOK-NAME/prod/

# Update book index.yaml
vim bookrack/YOUR-BOOK-NAME/index.yaml
# chapters:
#   - dev
#   - staging
#   - prod
```

### 6. Implement Progressive Delivery

Use Argo Rollouts for canary and blue-green deployments:

```bash
# Install Argo Rollouts
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# Add rollout strategy to spell
cat > bookrack/YOUR-BOOK-NAME/applications/api-rollout.yaml <<'EOF'
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
cat > bookrack/YOUR-BOOK-NAME/infrastructure/service-monitor.yaml <<'EOF'
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
# bookrack/YOUR-BOOK-NAME/infrastructure/network-policy.yaml
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
- [kast-system docs/](../docs/)
- [GETTING_STARTED.md](./GETTING_STARTED.md) - Detailed bookrack usage
- [LIBRARIAN.md](./LIBRARIAN.md) - Apps of Apps pattern
- [SUMMON.md](./SUMMON.md) - Workload chart reference
- [GLYPHS.md](./GLYPHS.md) - Available glyphs

**Testing:**
```bash
# TDD workflow
cd vendor/kast-system
make test              # Run comprehensive tests
make test-status       # Check test coverage
make list-glyphs       # List available glyphs
```

**Community:**
- GitHub Issues: https://github.com/kast-spells/kast-system/issues
- Documentation: https://docs.runik.ing

---

**Congratulations!** 🎉 You now have a fully functional GitOps workflow with ArgoCD and kast-system.

Your next commit to the bookrack repository will automatically trigger a deployment.

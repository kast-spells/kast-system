# Bootstrapping Guide

Complete guide for bootstrapping a Kubernetes cluster with ArgoCD and kast-system from scratch.

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


### 5. Verify ArgoCD Applications

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



**→ [Bootstrapping Troubleshooting Guide](BOOTSTRAPPING_TROUBLESHOOTING.md)**


**Congratulations!** 🎉 You now have a fully functional GitOps workflow with ArgoCD and kast-system.

Your next commit to the bookrack repository will automatically trigger a deployment.
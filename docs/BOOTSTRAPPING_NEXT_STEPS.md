# Bootstrapping: Next Steps

After successfully bootstrapping your cluster with ArgoCD and runik-system, this guide helps you expand your deployment with advanced features.

**Related:** [Bootstrapping Guide](BOOTSTRAPPING.md) | [Troubleshooting](BOOTSTRAPPING_TROUBLESHOOTING.md)

---

## Table of Contents

1. [Add More Glyphs](#1-add-more-glyphs)
2. [Setup Lexicon for Infrastructure Discovery](#2-setup-lexicon-for-infrastructure-discovery)
3. [Enable Auto-Sync for GitOps](#3-enable-auto-sync-for-gitops)
4. [Add Webhook for Fast Sync](#4-add-webhook-for-fast-sync)
5. [Multi-Environment Setup](#5-multi-environment-setup)
6. [Implement Progressive Delivery](#6-implement-progressive-delivery)
7. [Monitoring and Observability](#7-monitoring-and-observability)
8. [Security Hardening](#8-security-hardening)
9. [Backup and Disaster Recovery](#9-backup-and-disaster-recovery)
10. [Learn More](#10-learn-more)

---

## 1. Add More Glyphs

Enhance your spells with infrastructure glyphs:

### Vault Integration (Secrets Management)

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

**Documentation:** [Vault Glyph](VAULT.md)

### Istio Integration (Service Mesh)

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

**Documentation:** [Istio Glyph](glyphs/istio.md)

### cert-manager Integration (TLS Certificates)

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

**Documentation:** [cert-manager Glyph](glyphs/certmanager.md)

**See also:** [Glyphs Reference](GLYPHS_REFERENCE.md) for all available glyphs

---

## 2. Setup Lexicon for Infrastructure Discovery

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

**Documentation:** [Lexicon Guide](LEXICON.md)

---

## 3. Enable Auto-Sync for GitOps

Configure ArgoCD to automatically sync on git changes:

### Via ArgoCD CLI

```bash
# Enable auto-sync for all applications in book
argocd app set -l argocd.argoproj.io/instance=my-book \
  --sync-policy automated \
  --auto-prune \
  --self-heal
```

### Via kubectl

```bash
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

### Via Book Configuration

```yaml
# bookrack/my-book/index.yaml
appParams:
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
  disableAutoSync: false  # Ensure auto-sync is enabled
```

---

## 4. Add Webhook for Fast Sync

Configure webhook for instant synchronization:

```bash
# Get webhook URL
echo "https://$(kubectl get ingress -n argocd argocd-server -o jsonpath='{.spec.rules[0].host}')/api/webhook"

# Configure in your git provider (GitHub, GitLab, etc.):
# URL: https://argocd.example.com/api/webhook
# Content type: application/json
# Events: push, pull_request
```

**GitHub example:**
1. Go to repository Settings → Webhooks → Add webhook
2. Payload URL: `https://argocd.example.com/api/webhook`
3. Content type: `application/json`
4. Events: "Just the push event"
5. Active: checked

---

## 5. Multi-Environment Setup

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

**Alternative: Use chapters for environments**

```yaml
# bookrack/my-book/index.yaml
name: my-book
chapters:
  - dev
  - staging
  - production

# Each chapter can have different configuration
```

**Documentation:** [Bookrack Guide](BOOKRACK.md)

---

## 6. Implement Progressive Delivery

Use Argo Rollouts for canary and blue-green deployments:

### Install Argo Rollouts

```bash
# Install Argo Rollouts
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
```

### Add Rollout Strategy to Spell

```yaml
# bookrack/my-book/applications/api-rollout.yaml
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
```

**See also:** [Argo Rollouts Documentation](https://argoproj.github.io/argo-rollouts/)

---

## 7. Monitoring and Observability

Add Prometheus metrics and Grafana dashboards:

### Install kube-prometheus-stack

```bash
# Install kube-prometheus-stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace
```

### Add ServiceMonitor for Applications

```yaml
# bookrack/my-book/infrastructure/service-monitor.yaml
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
```

### Enable Metrics in Spell

```yaml
# bookrack/my-book/applications/api.yaml
name: api

image:
  repository: myorg/api
  tag: v1.0

service:
  enabled: true
  ports:
    - name: http
      port: 80
      targetPort: http
    - name: metrics  # Add metrics port
      port: 9090
      targetPort: metrics

# Add prometheus annotations
podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "9090"
  prometheus.io/path: "/metrics"
```

---

## 8. Security Hardening

### Add NetworkPolicies

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

### Add PodSecurityContext

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

### Enable Pod Security Standards

```bash
# Label namespace with pod security standard
kubectl label namespace my-book-applications \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted
```

**See also:** [Good Practices - Security](GOOD_PRACTICES.md#security)

---

## 9. Backup and Disaster Recovery

### Backup ArgoCD Configuration

```bash
# Backup ArgoCD configuration
argocd admin export > argocd-backup.yaml

# Backup applications
kubectl get applications -n argocd -o yaml > applications-backup.yaml
```

### Schedule Regular Backups with Velero

```bash
# Install Velero
helm install velero vmware-tanzu/velero \
  --namespace velero \
  --create-namespace \
  --set configuration.backupStorageLocation[0].bucket=argocd-backups

# Create backup schedule
velero schedule create daily-backup \
  --schedule="@daily" \
  --include-namespaces argocd,my-book-applications
```

### Test Disaster Recovery

```bash
# Test restore procedure
velero backup create manual-backup \
  --include-namespaces argocd

# Simulate disaster (delete namespace)
kubectl delete namespace my-book-applications

# Restore from backup
velero restore create --from-backup manual-backup
```

---

## 10. Learn More

### Documentation

**Core Components:**
- [Librarian Guide](LIBRARIAN.md) - Apps of Apps pattern
- [Librarian Internals](LIBRARIAN_INTERNALS.md) - Technical deep dive
- [Summon Guide](SUMMON.md) - Workload chart reference
- [Kaster Guide](KASTER.md) - Glyph orchestration
- [Bookrack Guide](BOOKRACK.md) - Configuration management

**Glyphs:**
- [Glyphs Overview](GLYPHS.md) - Available glyphs
- [Glyphs Reference](GLYPHS_REFERENCE.md) - Quick reference
- [Glyph Development](GLYPH_DEVELOPMENT.md) - Creating new glyphs
- [Vault Glyph](VAULT.md) - Secrets management
- Individual glyph docs in `docs/glyphs/`

**Trinkets:**
- [Microspell](MICROSPELL.md) - Microservices pattern
- [Tarot](TAROT.md) - Workflow automation

**Development:**
- [Getting Started](GETTING_STARTED.md) - Complete tutorial
- [Testing Guide](TESTING.md) - TDD methodology
- [TDD Commands](TDD_COMMANDS.md) - Command reference
- [Good Practices](GOOD_PRACTICES.md) - Best practices
- [Glossary](GLOSSARY.md) - Terminology reference

**External Resources:**
- [ArgoCD Official Docs](https://argo-cd.readthedocs.io/)
- [Helm Official Docs](https://helm.sh/docs/)
- [Kubernetes Official Docs](https://kubernetes.io/docs/)

### Testing

```bash
# TDD workflow
cd vendor/runik-system
make test              # Run comprehensive tests
make test-status       # Check test coverage
make list-glyphs       # List available glyphs
```

### Community

- **GitHub Issues:** https://github.com/runik-spells/runik-system/issues
- **Documentation:** https://docs.runik.ing

---

**Congratulations!** You now have a fully functional GitOps workflow with ArgoCD and runik-system.

Your next commit to the bookrack repository will automatically trigger a deployment.

---

**Back to:** [Bootstrapping Guide](BOOTSTRAPPING.md)

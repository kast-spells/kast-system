# Bootstrapping Troubleshooting Guide

Common issues and solutions when bootstrapping a Kubernetes cluster with ArgoCD and kast-system.

**Related:** [Bootstrapping Guide](BOOTSTRAPPING.md)

---

## Table of Contents

1. [ArgoCD Installation Issues](#argocd-installation-issues)
2. [Librarian Issues](#librarian-issues)
3. [Spell Deployment Issues](#spell-deployment-issues)
4. [Common Helm Errors](#common-helm-errors)
5. [Debugging Commands Reference](#debugging-commands-reference)

---

## ArgoCD Installation Issues

### Issue: Pods stuck in Pending state
```bash
# Check pod events
kubectl describe pod -n argocd <pod-name>

# Common causes:
# 1. Insufficient cluster resources
kubectl top nodes
kubectl describe nodes

# 2. Image pull errors
kubectl get events -n argocd --field-selector reason=Failed

# 3. PersistentVolume issues (if using HA redis)
kubectl get pv,pvc -n argocd
```

**Solution:**
```bash
# For resource constraints, reduce replica counts
helm upgrade argocd argo/argo-cd \
  --namespace argocd \
  --reuse-values \
  --set server.replicas=1 \
  --set repoServer.replicas=1

# For PV issues, use redis instead of redis-ha
helm upgrade argocd argo/argo-cd \
  --namespace argocd \
  --reuse-values \
  --set redis.enabled=true \
  --set redis-ha.enabled=false
```

### Issue: Cannot access ArgoCD UI

```bash
# Check ingress status
kubectl get ingress -n argocd
kubectl describe ingress -n argocd argocd-server

# Check ingress controller
kubectl get pods -n ingress-nginx

# Check service
kubectl get svc -n argocd argocd-server
```

**Solution:**
```bash
# Use port-forward as fallback
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Check ingress controller logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Verify ingress class
kubectl get ingressclass
```

### Issue: Initial admin password not found

```bash
# Check if secret exists
kubectl get secret -n argocd argocd-initial-admin-secret

# If missing, check ArgoCD server logs
kubectl logs -n argocd deployment/argocd-server
```

**Solution:**
```bash
# Reset admin password via ArgoCD server pod
kubectl exec -n argocd deployment/argocd-server -- \
  argocd admin initial-password

# Or reset via bcrypt hash in secret
kubectl patch secret argocd-secret -n argocd \
  --type merge \
  -p '{"stringData":{"admin.password":"'$(htpasswd -nbBC 10 "" your-new-password | tr -d ':\n' | sed 's/$2y/$2a/')'"}}'

# Restart server to apply
kubectl rollout restart deployment/argocd-server -n argocd
```

## Librarian Issues

### Issue: Librarian not creating ArgoCD Applications

**Check librarian Application status:**
```bash
# If deployed via Option A or B (ArgoCD Application)
argocd app get librarian-my-book

# Check sync status
kubectl get application -n argocd librarian-my-book -o yaml

# View librarian logs (check Application controller logs)
kubectl logs -n argocd deployment/argocd-application-controller | grep librarian-my-book
```

**Common causes:**
1. Repository URL incorrect in Application spec
2. Git credentials missing for private repositories
3. Invalid book structure in bookrack/
4. YAML syntax errors in index.yaml or spells
5. Symlink broken (if using Option C - local Helm install)

**Solution:**
```bash
# 1. Verify repository is accessible
argocd repo list
# If not listed, add it:
argocd repo add https://github.com/your-org/my-bookrack.git

# 2. For private repositories, add credentials:
argocd repo add https://github.com/your-org/my-bookrack.git \
  --username your-username \
  --password your-token

# 3. Validate book structure locally
cd ~/my-bookrack
git submodule update --init --recursive
cd vendor/kast-system
make test-book BOOK=../../bookrack/my-book

# 4. Check Application source path
kubectl get application -n argocd librarian-my-book \
  -o jsonpath='{.spec.source.path}'
# Should be: vendor/kast-system/librarian

# 5. Force refresh and sync
argocd app get librarian-my-book --refresh
argocd app sync librarian-my-book

# 6. If using Option C and symlink is broken:
# See BOOTSTRAPPING.md "Option C" for symlink fix
```

### Issue: Librarian deployed but no child Applications created

**Check if librarian processed the book:**
```bash
# List all Applications
kubectl get applications -n argocd

# Expected: Should see applications like:
# - my-book-infrastructure-<spell-name>
# - my-book-applications-<spell-name>

# If only librarian-my-book exists, check:

# 1. Verify book name matches
kubectl get application -n argocd librarian-my-book \
  -o jsonpath='{.spec.source.helm.values}' | grep name

# 2. Check librarian rendered successfully
argocd app manifests librarian-my-book | grep "kind: Application"

# 3. Check for errors in ArgoCD
argocd app get librarian-my-book --show-operation

# 4. Verify bookrack structure
# ArgoCD should have cloned the repo and found:
# - bookrack/my-book/index.yaml
# - bookrack/my-book/<chapter>/*.yaml
```

**Solution:**
```bash
# Check book index.yaml is valid
cat bookrack/my-book/index.yaml
# Must have:
# - name: my-book
# - chapters: [...]

# Verify chapters exist
ls -la bookrack/my-book/

# Check spell files exist
ls -la bookrack/my-book/applications/

# Re-sync librarian to regenerate Applications
argocd app sync librarian-my-book --force
```

### Issue: Applications created but not syncing

```bash
# Check application status
argocd app get my-book-applications-nginx

# Check sync status
kubectl get application -n argocd my-book-applications-nginx -o yaml
```

**Solution:**
```bash
# Check repository credentials
argocd repo list

# Refresh repository
argocd app get my-book-applications-nginx --refresh

# Force sync
argocd app sync my-book-applications-nginx --force

# Check if auto-sync is disabled
argocd app set my-book-applications-nginx --sync-policy automated
```

## Spell Deployment Issues

### Issue: Spell not rendering correctly

```bash
# Test spell locally with Helm
cd vendor/kast-system
make create-example CHART=summon EXAMPLE=test-nginx

# Copy your spell
cp ../../bookrack/my-book/applications/nginx.yaml \
  charts/summon/examples/test-nginx.yaml

# Test rendering
make test CHART=summon EXAMPLE=test-nginx
```

**Solution:**
```bash
# Check for YAML syntax errors
yamllint bookrack/my-book/applications/nginx.yaml

# Validate with Helm
helm template test ./vendor/kast-system/charts/summon \
  --values bookrack/my-book/applications/nginx.yaml

# Check librarian generated values
kubectl get application -n argocd my-book-applications-nginx -o yaml
```

### Issue: Glyph resources not created (vault, istio, etc.)

```bash
# Check if kaster is being invoked
kubectl get application -n argocd | grep kaster

# Check application sources
kubectl get application -n argocd my-book-applications-nginx -o yaml | grep -A 20 sources
```

**Common causes:**
1. Missing trinket definition in book index.yaml
2. Glyph key not stripped by librarian (external chart + direct glyph type)
3. Kaster application not created

**Solution:**
```bash
# Verify trinket is registered in book index.yaml
cat bookrack/my-book/index.yaml | grep -A 5 trinkets

# For external charts, use glyphs: wrapper
cat > bookrack/my-book/applications/nginx-external.yaml <<'EOF'
name: nginx-external

# External chart
repository: https://charts.bitnami.com/bitnami
chart: nginx

# Use glyphs wrapper for external charts
glyphs:
  vault:
    my-secret:
      path: secret/data/nginx
EOF

# Commit and push
git add bookrack/my-book/applications/nginx-external.yaml
git commit -m "Fix glyph invocation"
git push
```

### Issue: Namespace not created

ArgoCD creates namespaces automatically if they don't exist, but check:

```bash
# List all namespaces
kubectl get namespaces

# Check application destination
kubectl get application -n argocd my-book-applications-nginx \
  -o jsonpath='{.spec.destination.namespace}'
```

**Solution:**
```bash
# Manually create namespace if needed
kubectl create namespace my-book-applications

# Or set namespace in spell
cat > bookrack/my-book/applications/nginx.yaml <<'EOF'
name: nginx
namespace: my-book-applications  # Explicit namespace

image: nginx:1.25-alpine
# ... rest of configuration
EOF
```

## Common Helm Errors

### Issue: Helm release not found

```bash
# List Helm releases
helm list -A

# Check specific namespace
helm list -n my-book-applications
```

**Solution:**
```bash
# Uninstall stale release
helm uninstall <release-name> -n <namespace>

# Sync again via ArgoCD
argocd app sync my-book-applications-nginx
```

### Issue: CRD conflicts

```bash
# Check CRDs
kubectl get crds | grep argoproj

# Check for conflicts
kubectl get applications.argoproj.io -A
```

**Solution:**
```bash
# Re-install ArgoCD CRDs
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/crds/application-crd.yaml
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/crds/applicationset-crd.yaml
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/crds/appproject-crd.yaml

# Or use Helm chart with CRD installation
helm upgrade argocd argo/argo-cd \
  --namespace argocd \
  --reuse-values \
  --set crds.install=true
```

## Debugging Commands Reference

```bash
# ArgoCD
kubectl logs -n argocd deployment/argocd-server
kubectl logs -n argocd deployment/argocd-repo-server
kubectl logs -n argocd deployment/argocd-application-controller

# Librarian
kubectl logs -n argocd deployment/librarian

# Applications
argocd app get <app-name>
argocd app manifests <app-name>
argocd app resources <app-name>
argocd app history <app-name>

# Kubernetes
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Helm
helm get values <release-name> -n <namespace>
helm get manifest <release-name> -n <namespace>
helm history <release-name> -n <namespace>
```

---

**Back to:** [Bootstrapping Guide](BOOTSTRAPPING.md)

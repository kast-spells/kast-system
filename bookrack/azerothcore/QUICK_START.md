# AzerothCore Quick Start

## Deployment in 3 Commands

### 1. Test Infrastructure

```bash
cd /path/to/kast-system
make tdd-green
```

This validates all spells and generates manifests.

### 2. Deploy to Kubernetes

```bash
# Using librarian to generate ArgoCD Applications
kubectl apply -f <(make generate-book BOOK=azerothcore)
```

### 3. Monitor

```bash
# Watch deployment progress
kubectl get pods -n azerothcore -w

# Check external services
kubectl get svc -n azerothcore

# View logs
kubectl logs -n azerothcore -l app.kubernetes.io/part-of=azerothcore -f
```

## Access Game Server

### Get External IP

```bash
kubectl get svc -n azerothcore
```

Look for LoadBalancer external IPs:
- **Auth Server**: `<AUTH_IP>:3724`
- **World Server**: `<WORLD_IP>:8085`

### Test Connection

```bash
# Test auth server
nc -zv <AUTH_IP> 3724

# Test world server  
nc -zv <WORLD_IP> 8085
```

## Customize Before Deploy

### 1. Change Passwords

Edit `infrastructure/secrets.yaml`:

```yaml
glyphs:
  freeForm:
    mysql-credentials:
      data:
        MYSQL_ROOT_PASSWORD: <your-base64-encoded-password>
```

### 2. Adjust Resources

Edit `applications/worldserver.yaml` for your cluster:

```yaml
resources:
  limits:
    cpu: "4"      # Change this
    memory: 8Gi   # And this
```

### 3. Set Game Rates

Edit `infrastructure/secrets.yaml`:

```yaml
RATE_XP_KILL: "2"      # 2x experience
RATE_QUEST_REWARD: "2" # 2x quest rewards
```

## Troubleshooting

**Pods stuck in Pending:**
```bash
kubectl describe pod <pod-name> -n azerothcore
# Usually: not enough resources or PVC not bound
```

**Can't connect to auth server:**
```bash
kubectl logs -n azerothcore -l app.kubernetes.io/name=azerothcore-authserver
# Check pod status and service exposure
```

**World server crashes on startup:**
```bash
kubectl logs -n azerothcore -l app.kubernetes.io/name=azerothcore-worldserver --tail=200
# May need to increase resources or startup probe timeout
```

## Commands Reference

```bash
# Check everything
kubectl get all -n azerothcore

# Stream all logs
kubectl logs -n azerothcore -l app.kubernetes.io/part-of=azerothcore -f --all-containers

# Delete everything (cleanup)
kubectl delete namespace azerothcore

# Enter a container
kubectl exec -it -n azerothcore <pod-name> -- /bin/bash

# Check database
kubectl port-forward -n azerothcore svc/azerothcore-mysql 3306:3306
# Then: mysql -h 127.0.0.1 -u root -p acore_world
```

See `DEPLOYMENT_GUIDE.md` for complete documentation.

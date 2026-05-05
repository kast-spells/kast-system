# AzerothCore WotLK Kubernetes Deployment

Complete Helm chart and Kubernetes manifests for deploying AzerothCore (World of Warcraft private server emulator) using the kast-system framework.

## Architecture

### Components

1. **MySQL Database** (`infrastructure/mysql-database.yaml`)
   - MySQL 8.4 server
   - 50Gi persistent storage
   - 3 databases: acore_auth, acore_world, acore_characters
   - Service: `azerothcore-mysql:3306`

2. **Database Import Job** (`infrastructure/db-import-job.yaml`)
   - Initializes databases with game content
   - Runs as Kubernetes Job
   - Depends on MySQL being ready

3. **Authentication Server** (`applications/authserver.yaml`)
   - 2 replicas for HA
   - Handles player account authentication
   - LoadBalancer service on port 3724
   - Pod disruption budget for safe updates

4. **World Server** (`applications/worldserver.yaml`)
   - Main game server
   - World simulation and player interactions
   - LoadBalancer service (ports 8085: world, 7878: SOAP)
   - 4 CPU / 8Gi memory for game simulation
   - Startup probe to handle slow initialization

5. **Secrets & Configuration** (`infrastructure/secrets.yaml`)
   - Sensitive credentials (MySQL passwords)
   - Server configuration (realm name, experience rates, etc.)

6. **Networking** (`infrastructure/networking.yaml`)
   - Istio VirtualServices for routing
   - Supports DNS-based service discovery
   - Exports services cluster-wide

## Deployment Steps

### 1. Verify Prerequisites

```bash
# Ensure kubectl is configured
kubectl cluster-info

# Check available storage
kubectl get storageclasses

# Verify namespace doesn't exist (will be created)
kubectl get namespace azerothcore 2>/dev/null || echo "Namespace will be created"
```

### 2. Deploy Using kast-system

```bash
# From kast-system root directory

# Option A: Deploy entire AzerothCore book
make test comprehensive book azerothcore

# Option B: Deploy individual components
make test comprehensive spell mysql-database BOOK=azerothcore
make test comprehensive spell db-import-job BOOK=azerothcore
make test comprehensive spell authserver BOOK=azerothcore
make test comprehensive spell worldserver BOOK=azerothcore
```

### 3. Librarian ArgoCD Integration

```bash
# Generate ArgoCD Applications from the book
# (Librarian will create multi-source Applications)

# Verify generated manifests
kubectl get applications -n argocd -l app.kubernetes.io/part-of=azerothcore
```

### 4. Monitor Deployment

```bash
# Watch all AzerothCore components
kubectl get all -n azerothcore -w

# Check database readiness
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=azerothcore-mysql \
  -n azerothcore --timeout=300s

# Check auth server
kubectl logs -n azerothcore \
  -l app.kubernetes.io/name=azerothcore-authserver \
  --tail=100 -f

# Check world server
kubectl logs -n azerothcore \
  -l app.kubernetes.io/name=azerothcore-worldserver \
  --tail=100 -f
```

## Configuration

### Database Passwords

**⚠️ SECURITY WARNING**: Default passwords are for development only!

Edit `infrastructure/secrets.yaml`:
- `MYSQL_ROOT_PASSWORD`
- `MYSQL_AC_AUTH_PASSWORD`
- `MYSQL_AC_WORLD_PASSWORD`
- `MYSQL_AC_CHARACTERS_PASSWORD`

### Game Rates

Modify `infrastructure/secrets.yaml` `server-config` ConfigMap:
- `RATE_XP_KILL`: Experience gain multiplier
- `RATE_XP_QUEST`: Quest experience multiplier
- `RATE_QUEST_REWARD`: Quest reward multiplier
- `RATE_HONOR`: PvP honor multiplier

### Server Resources

Adjust resource requests/limits:
- **MySQL**: Default 1-2 CPU / 2-4Gi memory
- **Auth Server**: Default 500m-1 CPU / 512Mi-1Gi memory
- **World Server**: Default 2-4 CPU / 4-8Gi memory

Increase for production:

```yaml
# In worldserver.yaml
resources:
  limits:
    cpu: "8"
    memory: 16Gi
  requests:
    cpu: "4"
    memory: 8Gi
```

### Database Persistence

Default: 50Gi for MySQL

Change in `infrastructure/mysql-database.yaml`:
```yaml
volumes:
  mysql-data:
    type: pvc
    size: 200Gi  # Adjust as needed
```

## Service Access

### Internal (within cluster)

```bash
# Auth Server
azerothcore-authserver:3724

# World Server
azerothcore-worldserver:8085 (game)
azerothcore-worldserver:7878 (SOAP admin)

# MySQL
azerothcore-mysql:3306
```

### External (LoadBalancer)

```bash
# Get external IPs
kubectl get svc -n azerothcore

# Connect to auth server
<EXTERNAL_IP>:3724

# Connect to world server
<EXTERNAL_IP>:8085
```

### DNS (with Istio)

```bash
# If using Istio networking:
auth.azerothcore.local:3724
world.azerothcore.local:8085
soap.azerothcore.local:7878
```

## Troubleshooting

### Database not starting

```bash
# Check MySQL logs
kubectl logs -n azerothcore azerothcore-mysql-xxx

# Check PVC status
kubectl get pvc -n azerothcore
kubectl describe pvc mysql-data -n azerothcore

# Check storage class
kubectl get storageclasses
```

### Auth server connection refused

```bash
# Verify service exists
kubectl get svc -n azerothcore azerothcore-authserver

# Check pod status
kubectl get pods -n azerothcore -l app.kubernetes.io/name=azerothcore-authserver

# Check logs
kubectl logs -n azerothcore -l app.kubernetes.io/name=azerothcore-authserver
```

### World server crashes during startup

```bash
# World server is resource-intensive - check resource availability
kubectl top nodes

# Check startup probe logs
kubectl describe pod -n azerothcore \
  -l app.kubernetes.io/name=azerothcore-worldserver

# Increase startup probe timeout:
# (in worldserver.yaml, increase failureThreshold)
startupProbe:
  failureThreshold: 50  # Default 30, increase for slower systems
```

### Database import job fails

```bash
# Check job status
kubectl get jobs -n azerothcore
kubectl describe job azerothcore-db-import -n azerothcore

# Check job logs
kubectl logs -n azerothcore job/azerothcore-db-import

# Restart job if needed
kubectl delete job azerothcore-db-import -n azerothcore
# Then redeploy
```

## Updates and Patches

### Update container images

Edit the respective spell files:
- `applications/authserver.yaml`: Update `image.tag`
- `applications/worldserver.yaml`: Update `image.tag`

Example:
```yaml
image:
  repository: azerothcore/azerothcore
  tag: authserver-v1.2.3  # Update this
```

Then redeploy:
```bash
make test comprehensive spell authserver BOOK=azerothcore
```

### Database migrations

If using newer AzerothCore versions with database schema changes:

1. Backup current database
2. Update `infrastructure/db-import-job.yaml` image tag
3. Rerun the import job
4. Redeploy world server

```bash
kubectl delete job azerothcore-db-import -n azerothcore
make test comprehensive spell db-import-job BOOK=azerothcore
```

## Production Considerations

1. **High Availability**: Auth server already has 2 replicas and pod disruption budget
2. **Database Backup**: Configure persistent volume backups
3. **Resource Quotas**: Add namespace resource limits
4. **NetworkPolicies**: Restrict traffic between namespaces
5. **TLS**: Configure Istio mTLS for inter-pod communication
6. **Monitoring**: Add Prometheus metrics scraping
7. **Logging**: Centralize logs using ELK or similar

## Book Structure

```
azerothcore/
├── index.yaml                          # Book metadata and config
├── DEPLOYMENT_GUIDE.md                 # This file
├── infrastructure/
│   ├── mysql-database.yaml             # MySQL Deployment
│   ├── db-import-job.yaml              # Database init Job
│   ├── secrets.yaml                    # Secrets & ConfigMaps
│   └── networking.yaml                 # Istio VirtualServices
└── applications/
    ├── authserver.yaml                 # Auth server Deployment
    └── worldserver.yaml                # World server Deployment
```

## Related Commands

```bash
# View all AzerothCore resources
kubectl get all -n azerothcore

# Get detailed status
kubectl describe namespace azerothcore
kubectl describe statefulsets -n azerothcore
kubectl describe deployments -n azerothcore

# Port forward for local testing
kubectl port-forward -n azerothcore svc/azerothcore-mysql 3306:3306
kubectl port-forward -n azerothcore svc/azerothcore-authserver 3724:3724
kubectl port-forward -n azerothcore svc/azerothcore-worldserver 8085:8085

# Execute commands in containers
kubectl exec -it -n azerothcore <POD_NAME> -- /bin/bash

# Scale replicas
kubectl scale deployment azerothcore-authserver --replicas=3 -n azerothcore

# Delete entire AzerothCore deployment
kubectl delete namespace azerothcore
```

## Resources

- [AzerothCore Repository](https://github.com/azerothcore/azerothcore-wotlk)
- [kast-system Documentation](https://github.com/kast-spells/kast-system)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Helm Documentation](https://helm.sh/docs/)

## License

This deployment configuration is provided as part of the kast-system framework.
AzerothCore is licensed under GNU GPL v3.

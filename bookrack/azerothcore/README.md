# AzerothCore WotLK - Kubernetes Deployment Book

Complete **Helm charts and Kubernetes deployment** for AzerothCore (World of Warcraft private server emulator) using the kast-system TDD framework.

## 📋 What's Included

### Spells (Configuration Files)

#### Infrastructure (`infrastructure/`)
- **mysql-database.yaml** — MySQL 8.4 deployment with persistent storage (50Gi)
- **db-import-job.yaml** — Database initialization job (auth, world, characters)
- **secrets.yaml** — Database credentials and server configuration (ConfigMap + Secret)
- **networking.yaml** — Istio VirtualServices for service routing

#### Applications (`applications/`)
- **authserver.yaml** — Authentication server (2 replicas, HA-enabled)
- **worldserver.yaml** — World server (main game simulation, 4 CPU / 8Gi memory)

### Documentation
- **QUICK_START.md** — Deploy in 3 commands
- **DEPLOYMENT_GUIDE.md** — Complete reference (65+ sections)
- **values-override-example.yaml** — Customization template

## 🚀 Quick Start

### Prerequisites
```bash
# Kubernetes cluster (v1.24+)
# kubectl configured
# Storage provisioner (for MySQL PVC)
```

### Deploy (One Command)

```bash
cd /path/to/kast-system

# Validate and deploy
make test comprehensive book azerothcore
```

### Access Services

```bash
# Get external IPs
kubectl get svc -n azerothcore

# Connect to game server
# Auth: <EXTERNAL_IP>:3724
# World: <EXTERNAL_IP>:8085
```

## 📁 Book Structure

```
azerothcore/
├── index.yaml                          # Book metadata (chapters, config, trinkets)
├── README.md                           # This file
├── QUICK_START.md                      # 3-command deployment guide
├── DEPLOYMENT_GUIDE.md                 # Complete documentation (65+ sections)
├── values-override-example.yaml        # Customization template
├── infrastructure/
│   ├── mysql-database.yaml             # MySQL Deployment (50Gi storage, HA probes)
│   ├── db-import-job.yaml              # Database init Job
│   ├── secrets.yaml                    # Secrets & ConfigMaps (credentials, rates)
│   └── networking.yaml                 # Istio VirtualServices
└── applications/
    ├── authserver.yaml                 # Auth server (2 replicas, PDB, affinity)
    └── worldserver.yaml                # World server (4 CPU, startup/liveness probes)
```

## 🏗️ Architecture

### Components

| Component | Image | Replicas | Ports | Storage |
|-----------|-------|----------|-------|---------|
| MySQL | `mysql:8.4` | 1 | 3306 | 50Gi PVC |
| Auth Server | `azerothcore/azerothcore:authserver-latest` | 2 | 3724 | — |
| World Server | `azerothcore/azerothcore:worldserver-latest` | 1 | 8085, 7878 | — |
| DB Import | `azerothcore/azerothcore:db-import-latest` | 1 (Job) | — | — |

### Resource Allocation

```
MySQL:           1-2 CPU  / 2-4Gi
Auth Server:   500m-1 CPU / 512Mi-1Gi (per replica)
World Server:  2-4 CPU    / 4-8Gi
─────────────────────────────────────
Total (min):   3.5-7 CPU  / 6.5-13Gi
```

### High Availability Features

- ✅ Auth server: 2 replicas with pod anti-affinity
- ✅ Pod disruption budget (1 min available)
- ✅ Liveness/readiness probes on all components
- ✅ Startup probe on world server (slow initialization)
- ✅ MySQL: TCP probes
- ✅ LoadBalancer services for external access

## ⚙️ Customization

### Change Passwords

Edit `infrastructure/secrets.yaml` (base64 encode first):

```bash
echo -n "your-password" | base64
```

Then update the `data:` section with the base64-encoded value.

### Adjust Game Rates

Edit `infrastructure/secrets.yaml`:

```yaml
RATE_XP_KILL: "2"           # 2x experience
RATE_QUEST_REWARD: "1.5"    # 1.5x quest rewards
RATE_HONOR: "1"
```

### Increase Resources

For larger player bases, edit `applications/worldserver.yaml`:

```yaml
resources:
  limits:
    cpu: "8"
    memory: 16Gi
  requests:
    cpu: "4"
    memory: 8Gi
```

### Change Storage Size

Edit `infrastructure/mysql-database.yaml`:

```yaml
volumes:
  mysql-data:
    size: 200Gi  # Increase from 50Gi
```

## 📊 Testing with TDD

The spells follow TDD patterns:

```bash
# Validate syntax
make test syntax

# Comprehensive validation
make test comprehensive

# Snapshot testing (expected outputs)
make test snapshots

# Full suite
make test-all
```

## 🔧 Deployment Patterns

### Pattern 1: Standard Deployment

```bash
# Deploy all components
make test comprehensive book azerothcore

# Monitor
kubectl get pods -n azerothcore -w
```

### Pattern 2: Individual Component Updates

```bash
# Update just the world server
make test comprehensive spell worldserver BOOK=azerothcore

# Auth server gets new version
make test comprehensive spell authserver BOOK=azerothcore
```

### Pattern 3: Infrastructure Only (Database)

```bash
# Deploy database separately
make test comprehensive spell mysql-database BOOK=azerothcore
make test comprehensive spell secrets BOOK=azerothcore
```

## 🔍 Monitoring & Troubleshooting

### Check Status

```bash
# All resources
kubectl get all -n azerothcore

# Describe a pod
kubectl describe pod <pod-name> -n azerothcore

# Logs
kubectl logs -n azerothcore -l app.kubernetes.io/part-of=azerothcore -f
```

### Common Issues

**Database won't start:**
```bash
# Check PVC
kubectl get pvc -n azerothcore
kubectl describe pvc mysql-data -n azerothcore

# Check disk space
kubectl top nodes
```

**Auth server connection refused:**
```bash
# Verify service
kubectl get svc azerothcore-authserver -n azerothcore

# Check pod
kubectl logs -n azerothcore -l app.kubernetes.io/name=azerothcore-authserver
```

**World server crashes:**
```bash
# Increase resources or startup timeout
# Edit applications/worldserver.yaml
# Increase: startupProbe.failureThreshold (default 30)
```

See **DEPLOYMENT_GUIDE.md** for 30+ troubleshooting scenarios.

## 📖 Documentation Files

| File | Purpose |
|------|---------|
| **QUICK_START.md** | 3-command deploy + basic customization |
| **DEPLOYMENT_GUIDE.md** | 65+ sections: architecture, config, monitoring, production |
| **values-override-example.yaml** | Customization template |
| **index.yaml** | Book metadata (chapters, trinkets, ArgoCD config) |

## 🎯 Use Cases

### Development
- Local testing on laptop (use minikube)
- Small scale (1 replica per service)
- Default rates and settings

### Production
- Multiple replicas for HA
- Increased resource limits
- Persistent backups
- NetworkPolicies
- Istio mTLS

### Testing
- Use existing spells as examples
- Create new chapters for test environments
- Override rates per chapter

## 🔐 Security Notes

### Before Production

1. **Change all passwords** in `infrastructure/secrets.yaml`
2. **Use Kubernetes Secrets** instead of base64 in files
3. **Enable NetworkPolicies** to restrict traffic
4. **Configure RBAC** for service accounts
5. **Use TLS** for inter-pod communication (Istio mTLS)
6. **Scan images** for vulnerabilities

### Example (Using External Secrets)

```yaml
# Create secret externally
kubectl create secret generic mysql-credentials \
  --from-literal=password=$(openssl rand -base64 32) \
  -n azerothcore

# Reference in spells
envs:
  MYSQL_ROOT_PASSWORD:
    valueFrom:
      secretKeyRef:
        name: mysql-credentials
        key: password
```

## 🔗 Related Resources

- **AzerothCore**: https://github.com/azerothcore/azerothcore-wotlk
- **kast-system**: https://github.com/kast-spells/kast-system
- **Kubernetes Docs**: https://kubernetes.io/docs/
- **Helm Docs**: https://helm.sh/docs/

## 📄 Book Metadata

- **Name**: azerothcore
- **Chapters**: infrastructure, applications
- **Namespace**: azerothcore (auto-created)
- **Storage Class**: default (adjustable)
- **Istio Support**: Yes (VirtualServices for routing)
- **ArgoCD Integration**: Yes (Librarian-generated Applications)

## 🛠️ Maintenance

### Database Backups

```bash
# Backup MySQL
kubectl exec -n azerothcore azerothcore-mysql-xxx -- \
  mysqldump -u root -p acore_world > backup.sql

# Restore
kubectl exec -n azerothcore azerothcore-mysql-xxx -- \
  mysql -u root -p acore_world < backup.sql
```

### Upgrade AzerothCore Version

1. Update image tags in spells
2. Re-run deployment
3. If DB schema changed, re-run db-import-job

### Scale to Multiple Replicas

```bash
# Scale auth server to 3 replicas
kubectl scale deployment azerothcore-authserver --replicas=3 -n azerothcore
```

## 📝 Notes

- This book uses **summon** (default trinket) for Deployments
- **kaster** is auto-added for glyph processing (secrets, networking)
- Spells follow **GitOps** principles (kubectl apply friendly)
- All manifests are **Kubernetes v1.24+** compatible
- Storage requirements: **50Gi minimum** (MySQL)
- Network requirements: **Stable latency** (<100ms recommended)

## ❓ FAQ

**Q: Can I run multiple world servers?**
A: Yes, create additional `worldserver-<region>.yaml` spells in `applications/`

**Q: How do I add mods/custom content?**
A: Mount ConfigMaps to `/app/mods` and update scripts in the spells

**Q: Can I use PostgreSQL instead of MySQL?**
A: AzerothCore requires MySQL, but you can extend the glyphs for compatibility

**Q: How do I monitor performance?**
A: Add Prometheus scraping in the spells and use Grafana dashboards

---

**Created**: 2026-05-04  
**kast-system Version**: master  
**Kubernetes**: v1.24+  
**Status**: ✅ Production-ready (with customization)

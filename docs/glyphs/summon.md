# Summon Glyph

Standard workload deployment templates.

## Templates

- `summon.workload.deployment` - Deployment resource
- `summon.workload.statefulset` - StatefulSet resource
- `summon.workload.daemonset` - DaemonSet resource
- `summon.workload.job` - Job resource
- `summon.workload.cronjob` - CronJob resource
- `summon.service` - Service resource
- `summon.serviceAccount` - ServiceAccount resource
- `summon.autoscaling` - HorizontalPodAutoscaler
- `summon.configMap` - ConfigMap resource
- `summon.secrets` - Secret resource
- `summon.pvc` - PersistentVolumeClaim

## Generated Resources

- `Deployment` (apps/v1)
- `StatefulSet` (apps/v1)
- `DaemonSet` (apps/v1)
- `Job` (batch/v1)
- `CronJob` (batch/v1)
- `Service` (v1)
- `ServiceAccount` (v1)
- `HorizontalPodAutoscaler` (autoscaling/v2)
- `ConfigMap` (v1)
- `Secret` (v1)
- `PersistentVolumeClaim` (v1)

## Parameters

### Workload

| Field | Type | Description |
|-------|------|-------------|
| `workload.type` | string | deployment/statefulset/daemonset/job/cronjob |
| `workload.replicas` | int | Number of replicas |
| `image.repository` | string | Container image |
| `image.tag` | string | Image tag |
| `volumes` | array | Volume definitions |

### Service

| Field | Type | Description |
|-------|------|-------------|
| `service.enabled` | bool | Create service |
| `service.type` | string | ClusterIP/LoadBalancer/NodePort |
| `service.ports` | array | Port definitions |

### Autoscaling

| Field | Type | Description |
|-------|------|-------------|
| `autoscaling.enabled` | bool | Create HPA |
| `autoscaling.minReplicas` | int | Minimum replicas |
| `autoscaling.maxReplicas` | int | Maximum replicas |
| `autoscaling.targetCPU` | int | Target CPU percentage |

## Examples

### Deployment

```yaml
name: my-app
workload:
  type: deployment
  replicas: 3
image:
  repository: nginx
  tag: alpine
service:
  enabled: true
  type: ClusterIP
  ports:
    - port: 80
```

### StatefulSet with Storage

```yaml
name: database
workload:
  type: statefulset
  replicas: 3
image:
  repository: postgres
  tag: 15
volumes:
  data:
    type: pvc
    size: 10Gi
    destinationPath: /var/lib/postgresql/data
```

## Testing

```bash
make test
make test-comprehensive
```

## Examples Location

`charts/summon/examples/`

## Note

Summon is also available as standalone chart: `charts/summon/`

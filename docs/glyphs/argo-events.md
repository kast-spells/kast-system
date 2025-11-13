# Argo Events Glyph

Event-driven workflows with Argo Events integration.

## Templates

- `argo-events.eventBus` - Event bus (JetStream)
- `argo-events.eventSource` - Event sources (GitHub, webhooks, etc.)
- `argo-events.sensor` - Event sensors and triggers

## Generated Resources

- `EventBus` (argoproj.io/v1alpha1)
- `EventSource` (argoproj.io/v1alpha1)
- `Sensor` (argoproj.io/v1alpha1)

## Parameters

### EventBus (`argo-events.eventBus`)

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | EventBus name |
| `jetstream.version` | string | JetStream version |
| `jetstream.replicas` | int | Number of replicas |
| `jetstream.persistence` | object | Storage configuration |

### EventSource (`argo-events.eventSource`)

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | EventSource name |
| `github` | map | GitHub webhook config |
| `webhook` | map | Generic webhook config |
| `calendar` | map | Calendar schedule config |
| `selector` | map | EventBus selector (uses lexicon) |

### Sensor (`argo-events.sensor`)

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Sensor name |
| `dependencies` | array | Event dependencies |
| `triggers` | array | Trigger actions |
| `selector` | map | EventBus selector (uses lexicon) |

## Examples

### EventBus

```yaml
glyphs:
  argo-events:
    production-bus:
      type: eventBus
      jetstream:
        version: "2.10.1"
        replicas: 3
        persistence:
          storageClassName: standard
          volumeSize: 10Gi
```

### GitHub EventSource

```yaml
glyphs:
  argo-events:
    github-webhooks:
      type: eventSource
      github:
        myrepo:
          owner: myorg
          repository: myrepo
          webhook:
            endpoint: /github
            port: "12000"
          events: [push, pull_request]
```

### Sensor

```yaml
glyphs:
  argo-events:
    build-trigger:
      type: sensor
      dependencies:
        - name: github-push
          eventSourceName: github-webhooks
          eventName: myrepo
      triggers:
        - name: start-build
          type: workflow
          workflow:
            operation: submit
            source:
              resource:
                apiVersion: argoproj.io/v1alpha1
                kind: Workflow
```

## Lexicon Integration

Sensors and EventSources use lexicon to discover EventBus via selectors.

```yaml
lexicon:
  - name: production-bus
    type: eventbus
    labels:
      environment: production
```

## Testing

```bash
make glyphs argo-events
```

## Examples Location

`charts/glyphs/argo-events/examples/`

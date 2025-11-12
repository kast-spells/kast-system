# Istio Glyph

Service mesh integration for traffic management and routing.

## Templates

- `istio.istio-gw` - Gateway resource
- `istio.virtualService` - VirtualService for routing

## Generated Resources

- `Gateway` (networking.istio.io/v1)
- `VirtualService` (networking.istio.io/v1)

## Parameters

### Gateway (`istio.istio-gw`)

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Gateway name |
| `hosts` | array | Hostnames |
| `istioSelector` | map | Selector for istio gateway pods |
| `tls.enabled` | bool | Enable TLS |
| `tls.issuerName` | string | cert-manager issuer |
| `ports` | array | Port configurations |

### VirtualService (`istio.virtualService`)

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | VirtualService name |
| `enabled` | bool | Enable resource |
| `subdomain` | string | Subdomain for routing |
| `host` | string | Service host |
| `httpRules` | array | HTTP routing rules |
| `selector` | map | Gateway selector (uses lexicon) |

## Examples

### Gateway

```yaml
glyphs:
  istio:
    - type: istio-gw
      name: external-gateway
      hosts:
        - "*.example.com"
      istioSelector:
        istio: external-gateway
      tls:
        enabled: true
        issuerName: letsencrypt-prod
      ports:
        - name: http
          port: 80
          protocol: HTTP
        - name: https
          port: 443
          protocol: HTTPS
```

### VirtualService

```yaml
glyphs:
  istio:
    - type: virtualService
      name: my-service
      enabled: true
      subdomain: myapp
      host: my-service
      httpRules:
        - prefix: /
          port: 80
      selector:
        access: external
```

## Lexicon Integration

VirtualService uses lexicon to discover gateways via selectors.

```yaml
lexicon:
  - name: external-gateway
    type: istio-gw
    labels:
      access: external
    gateway: istio-system/external-gateway
    baseURL: example.com
```

## Testing

```bash
make glyphs istio
```

## Examples Location

`charts/glyphs/istio/examples/`

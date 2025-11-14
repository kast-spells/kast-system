# Keycloak Glyph

Identity provider configuration via Keycloak operator.

## Templates

- `keycloak.keycloak` - Keycloak server instance
- `keycloak.realm` - Authentication realm
- `keycloak.client` - OAuth client
- `keycloak.clientScopes` - Client scopes
- `keycloak.user` - User management
- `keycloak.group` - User groups
- `keycloak.flow` - Authentication flows
- `keycloak.idp` - Identity provider

## Generated Resources

- `Keycloak` (k8s.keycloak.org/v2alpha1)
- `KeycloakRealm` (k8s.keycloak.org/v2alpha1)
- `KeycloakClient` (k8s.keycloak.org/v2alpha1)
- `KeycloakUser` (k8s.keycloak.org/v2alpha1)

## Examples

### Realm

```yaml
glyphs:
  keycloak:
    production:
      type: realm
      displayName: Production Environment
```

### Client

```yaml
glyphs:
  keycloak:
    my-app:
      type: client
      realm: production
      redirectUris:
        - https://myapp.example.com/*
```

## Testing

```bash
make glyphs keycloak
```

## Examples Location

`charts/glyphs/keycloak/examples/`

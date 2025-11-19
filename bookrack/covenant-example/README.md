# Covenant Example Book

Example book demonstrating the new modular covenant structure.

## Structure

```
covenant-example/
├── realm/                          # Realm configuration (main covenant)
│   ├── roles/                     # Realm roles
│   │   ├── developer.yaml
│   │   └── platform-engineer.yaml
│   ├── client-scopes/             # OIDC scopes
│   ├── idps/                      # Identity providers
│   ├── integrations/              # OIDC clients/apps
│   │   └── argocd.yaml
│   └── auth-flows/                # Authentication flows
│
└── covenant/                       # Organization structure (HARDCODED name)
    ├── index.yaml                 # Covenant-wide config
    ├── scripts/                   # External scripts
    │   └── setup-argocd.sh
    │
    ├── engineering/               # Chapter (custom key)
    │   ├── index.yaml            # Chapter config + chapel list
    │   ├── platform/             # Chapel (custom key)
    │   │   └── john-doe.yaml    # User file
    │   └── backend/
    │       └── jane-smith.yaml
    │
    └── sales/                     # Chapter
        ├── index.yaml
        └── core/                  # Chapel
            └── bob-jones.yaml
```

## Key Concepts

### 1 Book = 1 Realm = 1 Covenant

- **realm/**: Technical realm configuration (roles, integrations, IDPs)
- **covenant/**: Organizational structure (chapters, chapels, users)

### Flow

1. **Main Covenant** (no chapterFilter):
   - Scans `realm/**/*.yaml` → generates KeycloakRealm, Clients, IDPs, etc.
   - Scans `covenant/index.yaml` → gets chapter list
   - Generates ApplicationSet for chapters

2. **Chapter Apps** (with chapterFilter):
   - Scans `covenant/{chapter}/index.yaml` → gets chapel list
   - Scans `covenant/{chapter}/**/*.yaml` → generates Users, Groups
   - Runs post-provisioning jobs

## Adding Resources

### Add a user:
```bash
# Create file: covenant/{chapter}/{chapel}/{username}.yaml
cat > covenant/engineering/platform/new-user.yaml <<EOF
firstName: New
lastName: User
overrideUsername: new.user
status: active
realmRoles:
  - developer
EOF
```

### Add a role:
```bash
# Create file: realm/roles/{role-name}.yaml
cat > realm/roles/admin.yaml <<EOF
name: admin
description: "Administrator role"
EOF
```

### Add an integration:
```bash
# Create file: realm/integrations/{app-name}.yaml
cat > realm/integrations/gitlab.yaml <<EOF
enabled: true
clientId: gitlab
webUrl: https://gitlab.example.org
redirectUris:
  - https://gitlab.example.org/users/auth/openid_connect/callback
secret: keycloak-client-gitlab
EOF
```

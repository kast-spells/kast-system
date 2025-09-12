{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

vault.server creates a Vault server instance using Bank-Vaults operator.
Follows standard glyph parameter pattern: (list $root $glyphDefinition).

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: Vault server configuration object (index . 1)

Example minimal glyph definition:
  vault:
    - type: server
      name: vault
      postgresSelector:
        app: vault-db
      gcpSelector:
        project: my-project

*/}}

{{- define "vault.server" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}
{{- $postgresServers := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.postgresSelector) "postgres" $root.Values.chapter.name ) | fromJson) "results" }}
{{- $gcpProjects := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.gcpSelector) "gcp" $root.Values.chapter.name ) | fromJson) "results" }}
{{- range $pgConf := $postgresServers }}
{{- range $gcp := $gcpProjects }}
---
apiVersion: "vault.banzaicloud.com/v1alpha1"
kind: Vault
metadata:
  name: {{ default "vault" $glyphDefinition.name }}
  namespace: {{ default "vault" $glyphDefinition.namespace }}
spec:
  size: {{ default 2 $glyphDefinition.size }}
  image: {{ default "hashicorp/vault:1.19" $glyphDefinition.image }}
  bankVaultsImage: {{ default "ghcr.io/bank-vaults/bank-vaults:latest" $glyphDefinition.bankVaultsImage }}
  annotations:
    common/annotation: "true"

  vaultAnnotations:
    type/instance: "vault"

  vaultConfigurerAnnotations:
    type/instance: "vaultconfigurer"

  vaultLabels:
    example.com/log-format: "json"

  vaultConfigurerLabels:
    example.com/log-format: "string"

  serviceAccount: {{ default "vault" $glyphDefinition.serviceAccount }}

  serviceType: {{ default "ClusterIP" $glyphDefinition.serviceType }}

  unsealConfig:
    options:
      preFlightChecks: true
      storeRootToken: true
    google:
      kmsKeyRing: {{ default "vault-keyring" $gcp.kmsKeyRing }}
      kmsCryptoKey: {{ default "vault-unseal-key" $gcp.kmsCryptoKey }}
      kmsLocation: {{ default "global" $gcp.kmsLocation }}
      kmsProject: {{ $gcp.projectId }}
      storageBucket: {{ default "vault-unseal-bucket" $gcp.storageBucket }}

  config:
    storage:
      postgresql:
        ha_enabled: "true"
        max_idle_connections: {{ default 10 $glyphDefinition.maxIdleConnections }}
    listener:
      tcp:
        address: "0.0.0.0:8200"
        tls_disable: {{ default true $glyphDefinition.tlsDisable }}
    ui: {{ default true $glyphDefinition.ui }}
    cluster_addr: "http://${.Env.POD_NAME}:8201"
    api_addr: http://{{ default $root.Values.spellbook.name $glyphDefinition.apiAddrOverride }}:8200

  externalConfig:
    policies:
      - name: allow_secrets
        rules: path "secret/*" { capabilities = ["create", "read", "update", "delete", "list"] }
      - name: allow_database
        rules: path "database/creds/*" { capabilities = ["read"] }
      - name: vault
        rules: |
          path "sys/mounts/*" { capabilities = ["create", "read", "update", "delete", "list", "sudo"] }
          path "sys/*" { capabilities = ["create", "read", "update", "delete", "list", "sudo"] }
          path "auth/*" { capabilities = ["create", "read", "update", "delete", "list", "sudo"] }
          path "secret/*" { capabilities = [ "create", "read", "update", "delete", "list"] }

    auth:
      - type: kubernetes
        path: {{ default "control-plane" $glyphDefinition.customAuthPath }}
        roles:
          - name: vault
            bound_service_account_names: vault
            bound_service_account_namespaces: vault
            policies: vault
            ttl: {{ default "30m" $glyphDefinition.authTTL }}

    secrets:
      - path: secret
        type: kv
        description: General secrets.
        options:
          version: 2
# vault write database/config/my-postgresql-database \
#     plugin_name="postgresql-database-plugin" \
#     allowed_roles="my-role" \
#     connection_url="postgresql://{{`{{username}}`}}:{{`{{password}}`}}@localhost:5432/database-name" \
#     username="vaultuser" \
#     password="vaultpass" \
#     password_authentication="scram-sha-256"
# vault write database/roles/my-role \
#     db_name="my-postgresql-database" \
#     creation_statements="CREATE ROLE \"{{`{{name}}`}}\" WITH LOGIN PASSWORD '{{`{{password}}`}}' VALID UNTIL '{{`{{expiration}}`}}'; \
#         GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{`{{name}}`}}\";" \
#     default_ttl="1h" \
#     max_ttl="24h"

      # - type: database
      #   description: MySQL Database secret engine.
      #   configuration:
      #     config:
      #       - name: my-mysql
      #         plugin_name: "mysql-database-plugin"
      #         connection_url: "{{`{{username}}`}}:{{`{{password}}`}}@tcp(mysql:3306)/"
      #         allowed_roles: [app]
      #         username: "root"
      #         password: "${env `MYSQL_ROOT_PASSWORD`}" # Example how to read environment variables, with the env function
      #         rotate: true # Ask bank-vaults to ask Vault to rotate the root credentials of MySQL
      #     roles:
      #       - name: app
      #         db_name: my-mysql
      #         creation_statements: "CREATE USER '{{`{{name}}`}}'@'%' IDENTIFIED BY '{{`{{password}}`}}'; GRANT ALL ON `app\_%`.* TO '{{`{{name}}`}}'@'%';"
      #         default_ttl: "2m"
      #         max_ttl: "10m"

  secretInitsConfig:
    - name: VAULT_PG_CONNECTION_URL
      valueFrom:
        secretKeyRef:
          name: {{ $pgConf.credentialsSecret }}
          key: uri

  envsConfig:
    - name: VAULT_PG_CONNECTION_URL
      valueFrom:
        secretKeyRef:
          name: {{ $pgConf.credentialsSecret }}
          key: uri

  istioEnabled: {{ default false $glyphDefinition.istioEnabled }}
{{- end }}
{{- end }}
{{- end }}
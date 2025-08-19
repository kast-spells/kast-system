{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

vault.oidcAuth creates OIDC authentication configuration for HashiCorp Vault.
Follows standard glyph parameter pattern: (list $root $glyphDefinition).

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: OIDC auth configuration object (index . 1)

Example minimal glyph definition:
  vault:
    - type: oidcAuth
      name: keycloak-oidc
      oidcSelector:
        provider: keycloak
      defaultRole: developer

*/}}

{{- define "vault.oidcAuth" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}
{{- $vaultServer := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.selector) "vault" $root.Values.chapter.name ) | fromJson) "results" }}
{{- $oidcProviders := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.oidcSelector) "oidc" $root.Values.chapter.name ) | fromJson) "results" }}
{{- range $vaultConf := $vaultServer }}
{{- range $oidc := $oidcProviders }}
---
apiVersion: redhatcop.redhat.io/v1alpha1
kind: AuthEngineMount
metadata:
  name: oidc
  namespace: {{ $vaultConf.namespace }}
spec:
  {{- include "vault.connect" (list $root $vaultConf "vault" $glyphDefinition.serviceAccount) | nindent 2 }}
  type: oidc
---
apiVersion: redhatcop.redhat.io/v1alpha1
kind: JWTOIDCAuthEngineConfig
metadata:
  name: {{ $glyphDefinition.name }}
  namespace: {{ $vaultConf.namespace }}
spec:
  {{- include "vault.connect" (list $root $vaultConf "vault" $glyphDefinition.serviceAccount) | nindent 2 }}
  OIDCCredentials:
    secret:
      name: {{ $oidc.credentialsSecret }}
    usernameKey: username
    passwordKey: password
  path: oidc
  OIDCDiscoveryURL: {{ $oidc.discoveryURL }}
  defaultRole: {{ default "developer" $glyphDefinition.defaultRole }}
---
apiVersion: redhatcop.redhat.io/v1alpha1
kind: JWTOIDCAuthEngineRole
metadata:
  name: {{ $glyphDefinition.name }}-admins
  namespace: {{ $vaultConf.namespace }}
spec:
  {{- include "vault.connect" (list $root $vaultConf "vault" $glyphDefinition.serviceAccount) | nindent 2 }}
  name: admin
  path: oidc
  roleType: oidc
  userClaim: "preferred_username"
  groupsClaim: "groups"
  tokenPolicies:
    - "admin"
    - "vault"
  allowedRedirectURIs:
    - "{{ $oidc.baseURL }}/ui/vault/auth/oidc/oidc/callback"
  boundClaims:
    groups:
      - "vault-admins"
---
apiVersion: redhatcop.redhat.io/v1alpha1
kind: JWTOIDCAuthEngineRole
metadata:
  name: {{ $glyphDefinition.name }}-devs
  namespace: {{ $vaultConf.namespace }}
spec:
  {{- include "vault.connect" (list $root $vaultConf "vault" $glyphDefinition.serviceAccount) | nindent 2 }}
  path: oidc
  name: developer
  roleType: oidc
  userClaim: "preferred_username"
  groupsClaim: "groups"
  tokenPolicies:
    - "developer"
  allowedRedirectURIs:
    - "{{ $oidc.baseURL }}/ui/vault/auth/oidc/oidc/callback"
  boundClaims:
    groups:
      - "developers"
---
apiVersion: redhatcop.redhat.io/v1alpha1
kind: Policy
metadata:
  name: developer
  namespace: {{ $vaultConf.namespace }}
spec:
  {{- include "vault.connect" (list $root $vaultConf "vault" $glyphDefinition.serviceAccount) | nindent 2 }}
  policy: |
    path "secret/data/{{ $root.Values.spellbook.name }}/publics/*" {
      capabilities = [ "read", "list"]
    }
    path "secret/data/develop/**/publics/*" {
      capabilities = [ "read", "list"]
    }
{{- end }}
{{- end }}
{{- end }}
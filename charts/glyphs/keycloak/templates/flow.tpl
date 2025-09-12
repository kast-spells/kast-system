{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "keycloaj.flow" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: v1.edp.epam.com/v1
kind: KeycloakAuthFlow
metadata:
  name: link-existing-user
  namespace: keycloak
spec:
  alias: link-existing-user
  builtIn: false
  providerId: basic-flow
  topLevel: true
  realmRef:
    name: sarasa
    kind: KeycloakRealm
  authenticationExecutions:
    - authenticator: idp-review-profile
      requirement: REQUIRED
      priority: 0
      authenticatorFlow: false
    - authenticator: idp-auto-link
      requirement: REQUIRED
      priority: 1
      authenticatorFlow: false
{{- end }}
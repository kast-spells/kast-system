{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

Covenant Realm - ServiceAccount & Vault Policy
Generates ServiceAccount for covenant and Vault policy for OIDC secret access
*/}}

{{- define "covenant.realm.serviceAccount.sa" -}}
{{- $bookPath := default .Release.Name .Values.name -}}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ $bookPath }}
  namespace: {{ .Release.Namespace }}
{{- end -}}

{{- define "covenant.realm.serviceAccount.vaultGlyphs" -}}
{{- $bookPath := default .Release.Name .Values.name -}}
{{- $vaultGlyphs := dict -}}
{{- $_ := set $vaultGlyphs "covenant-policy" (dict
  "type" "vaultPolicy"
  "nameOverride" $bookPath
  "serviceAccount" $bookPath
  "bookPublicsWrite" true
) }}
{{- $vaultGlyphs | toJson -}}
{{- end -}}

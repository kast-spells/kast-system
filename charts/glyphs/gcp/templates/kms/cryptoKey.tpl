{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "gcp.cryptoKey" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: kms.cnrm.cloud.google.com/v1beta1
kind: KMSCryptoKey
metadata:
  name: {{ $glyphDefinition.name }}
  labels:
    {{- include "common.all.labels" $root | nindent 4 }}
    {{- with $glyphDefinition.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $glyphDefinition.annotations }}
  annotations:
    {{- include "common.annotations" $root | nindent 4 }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  keyRingRef:
    name: {{ $glyphDefinition.keyRingRef }}
    {{- if $glyphDefinition.keyRingRefNamespace }}
    namespace: {{ $glyphDefinition.keyRingRefNamespace }}
    {{- end }}
  purpose: {{ default "ENCRYPT_DECRYPT" $glyphDefinition.purpose }}
{{- end }}
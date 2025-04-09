{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "default-verbs.clone-repo" -}}
{{- $root := index . 0 -}}
{{- $containerName := index . 1 -}}
{{- $container := index . 2 -}}
{{- $yaml := `
  parameters:
    - name: parameters
      value: cosa
  name: clone-repo
  image: alpine/git
  env:
    - name: GITHUB_TOKEN
      valueFrom:
        secretKeyRef:
          name: kast01-gh-token
          key: git-token
    - name: GITHUB_USER
      valueFrom:
        secretKeyRef:
          name: kast01-gh-token
          key: git-user
  volumeMounts:
    - name: ssh-key-volume
      mountPath: /root/.ssh/id_rsa
      subPath: ssh-privatekey
  command: [sh, -c]
` -}}
{{- $yaml | nindent 0 }}
{{- end -}}


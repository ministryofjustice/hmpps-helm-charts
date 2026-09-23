{{/* vim: set filetype=mustache: */}}
{{/*
Environment variables for postgres database restore
*/}}
{{- define "postgresRestore.envs" -}}
{{- if or (or .postgresDatabaseRestore.namespace_secrets .postgresDatabaseRestore.env) .postgresDatabaseRestore.egressProxySecretName -}}
env:
{{- if .postgresDatabaseRestore.egressProxySecretName }}
  {{- range list "HTTP_PROXY" "HTTPS_PROXY" "NO_PROXY" }}
  - name: {{ . }}
    valueFrom:
      secretKeyRef:
        key: {{ . }}
        name: {{ $.postgresDatabaseRestore.egressProxySecretName }}
        optional: true
  {{- end }}
{{- end }}
{{- range $secret, $envs := .postgresDatabaseRestore.namespace_secrets }}
  {{- range $key, $val := $envs }}
  - name: {{ $key }}
    valueFrom:
      secretKeyRef:
        key: {{ trimSuffix "?" $val }}
        name: {{ $secret }}{{ if hasSuffix "?" $val }}
        optional: true{{ end }}  {{- end }}
{{- end }}
{{- range $key, $val := .postgresDatabaseRestore.env }}
  - name: {{ $key }}
    value: "{{ $val }}"
{{- end -}}
{{- end -}}
{{- end -}}

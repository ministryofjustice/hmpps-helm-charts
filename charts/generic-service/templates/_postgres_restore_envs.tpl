{{/* vim: set filetype=mustache: */}}
{{/*
Environment variables for postgres database restore
*/}}
{{- define "postgresRestore.envs" -}}
{{- if .postgresDatabaseRestore.namespace_secrets -}}
env:
{{- range $secret, $envs := .postgresDatabaseRestore.namespace_secrets }}
  {{- range $key, $val := $envs }}
  - name: {{ $key }}
    valueFrom:
      secretKeyRef:
        key: {{ trimSuffix "?" $val }}
        name: {{ $secret }}{{ if hasSuffix "?" $val }}
        optional: true{{ end }}  {{- end }}
{{- end }}
{{- end -}}
{{- end -}}

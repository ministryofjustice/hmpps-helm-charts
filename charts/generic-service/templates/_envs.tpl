{{/* vim: set filetype=mustache: */}}
{{/*
Environment variables for web and worker containers
*/}}
{{- define "deployment.envs" -}}
{{- $appName := include "generic-service.name" . -}}
{{- if .Values.namespace_secrets -}}
env:
{{- range $secret, $envs := .Values.namespace_secrets }}
  {{- range $key, $val := $envs }}
  - name: {{ $key }}
    valueFrom:
      secretKeyRef:
        key: {{ $val }}
        name: {{ $secret }}
  {{- end }}
{{- end }}
{{- end -}}
{{- if .Values.env -}}
{{- range $key, $val := .Values.env }}
  - name: {{ $key }}
    value: "{{ $val }}"
{{- end }}
{{- end }}
{{- end -}}

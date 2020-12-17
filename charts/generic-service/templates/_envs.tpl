{{/* vim: set filetype=mustache: */}}
{{/*
Environment variables for web and worker containers
*/}}
{{- define "deployment.envs" -}}
{{- $appName := include "generic-service.name" . -}}
env:
{{- range $key, $val := .Values.secrets }}
  - name: {{ $key }}
    valueFrom:
      secretKeyRef:
        key: {{ $key }}
        name: {{ $appName }}
{{- end }}
{{- range $key, $val := .Values.env }}
  - name: {{ $key }}
    value: "{{ $val }}"
{{- end }}
{{- range $secret, $envs := .Values.namespace_secrets }}
  {{- range $key, $val := $envs }}
  - name: {{ $val }}
    valueFrom:
      secretKeyRef:
        key: {{ $key }}
        name: {{ $secret }}
  {{- end }}
{{- end }}
{{- end }}

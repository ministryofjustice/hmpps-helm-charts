{{/* vim: set filetype=mustache: */}}
{{/*
Environment variables for web and worker containers
*/}}
{{- define "deployment.envs" -}}
{{- $appName := include "generic-service.name" . -}}
{{- if or .Values.namespace_secrets .Values.env -}}
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
{{- range $key, $val := .Values.env }}
  - name: {{ $key }}
    value: "{{ $val }}"
{{- end }}
{{- end -}}
{{- end -}}

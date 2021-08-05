{{/* vim: set filetype=mustache: */}}
{{/*
Volumes for deployments
*/}}
{{- define "deployment.volumes" -}}
{{- $appName := include "generic-service.name" . -}}
{{- if .Values.namespace_secrets_to_file -}}
volumes:
{{- range $secret, $envs := .Values.namespace_secrets_to_file }}
  - name: vol-{{ $secret }}
    secret:
      secretName: {{ $secret }}
      items:
  {{- range $key, $val := $envs }}
      {{- range $val }}
      - key: {{ . }}
        path: {{ . }}
      {{- end }}
  {{- end }}
{{- end }}
{{- end }}
{{- end -}}

{{/* vim: set filetype=mustache: */}}
{{/*
Volume mounts for containers
*/}}
{{- define "deployment.volume_mounts" -}}
{{- $appName := include "generic-service.name" . -}}
{{- if .Values.namespace_secrets_to_file -}}
volumeMounts:
{{- range $secret, $envs := .Values.namespace_secrets_to_file }}
  {{- range $key, $val := $envs }}
  - name: vol-{{ $secret }}
    mountPath: {{ $key }}
    readOnly: true
  {{- end }}
{{- end }}
{{- end }}
{{- end -}}

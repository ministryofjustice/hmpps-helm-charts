{{/* vim: set filetype=mustache: */}}
{{/*
Environment variables for web and worker containers
*/}}
{{- define "deployment.envs" -}}
{{- $appName := include "generic-service.name" . -}}
{{- if or (or .Values.namespace_secrets .Values.env) .Values.env_comma_joined_from_list  -}}
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
{{- range $key, $val := .Values.env_comma_joined_from_list }}
  - name: {{ $key }}
    value: {{ include "app.joinListWithComma" $val | quote }}
{{- end }}
{{- end -}}
{{- end -}}

{{/* vim: set filetype=mustache: */}}
{{/*
Volumes for deployments
*/}}
{{- define "deployment.volumes" -}}
{{- $appName := include "generic-service.name" . -}}
{{- $useTraefik := eq .Values.ingress.enabled false -}}
{{- if or $useTraefik .Values.namespace_secrets_to_file -}}
volumes:
{{- if $useTraefik }}
  - name: traefik-config
    configMap:
      name: {{ include "generic-service.fullname" . }}-traefik
{{- end }}
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

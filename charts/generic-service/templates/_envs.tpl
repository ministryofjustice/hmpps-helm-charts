{{/* vim: set filetype=mustache: */}}
{{/*
Environment variables for web and worker containers
*/}}
{{- define "deployment.envs" -}}
{{- if or (or .namespace_secrets .env) .env_comma_joined_from_list .productId -}}
env:
{{- if .productId }}
  - name: PRODUCT_ID
    value: "{{ .productId }}"
{{- end }}
{{- range $secret, $envs := .namespace_secrets }}
  {{- range $key, $val := $envs }}
  - name: {{ $key }}
    valueFrom:
      secretKeyRef:
        key: {{ trimSuffix "?" $val }}
        name: {{ $secret }}{{ if hasSuffix "?" $val }}
        optional: true{{ end }}  {{- end }}
{{- end }}
{{- range $key, $val := .env }}
  - name: {{ $key }}
    value: "{{ $val }}"
{{- end }}
{{- range $key, $val := .env_comma_joined_from_list }}
  - name: {{ $key }}
    value: {{ $val | join "," | quote }}
{{- end }}
{{- end -}}
{{- end -}}

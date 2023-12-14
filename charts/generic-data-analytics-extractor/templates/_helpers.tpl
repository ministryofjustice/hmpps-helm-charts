{{/* vim: set filetype=mustache: */}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "app.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Expand the name of the chart.
The maximum length of the resource name is 52.
If an overridden name is provided it will be truncated at 52
If the default name is to be used it is made up of the release name (truncated to 27) and `-data-analytics-extractor` giving a maximum length of 52.
*/}}
{{- define "generic-data-analytics-extractor.name" -}}
{{- if .Values.nameOverride -}}
{{- .Values.nameOverride | trunc 52 -}}
{{- else -}}
{{ .Release.Name | trunc 27 -}}-data-analytics-extractor
{{- end -}}
{{- end -}}

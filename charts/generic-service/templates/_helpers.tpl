{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "generic-service.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "generic-service.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "generic-service.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "generic-service.labels" -}}
helm.sh/chart: {{ include "generic-service.chart" . }}
{{ include "generic-service.selectorLabels" . }}
{{- if .Values.image.tag }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "generic-service.selectorLabels" -}}
app: {{ include "generic-service.name" . }}
release: {{ .Release.Name }}
{{- end }}

{{/*
Create a string from a list of values joined by a comma
*/}}
{{- define "app.joinListWithComma" -}}
{{- $local := dict "first" true -}}
{{- range $k, $v := . -}}{{- if not $local.first -}},{{- end -}}{{- $v -}}{{- $_ := set $local "first" false -}}{{- end -}}
{{- end -}}

{{/*
Define the port to be used for the traefik proxy
*/}}
{{- define "generic-service.traefikProxyPort" -}}
{{- if eq .Values.image.port 9090.0 -}}
9091
{{- else -}}
9090
{{- end -}}
{{- end -}}

{{/*
Define the port to use for the traefik metrics
*/}}
{{- define "generic-service.traefikProxyMetricsPort" -}}
{{- if eq .Values.image.port 9390.0 -}}
9391
{{- else -}}
9390
{{- end -}}
{{- end -}}

{{/*
Define the port to use for the traefik healthcheck
*/}}
{{- define "generic-service.traefikProxyPingPort" -}}
{{- if eq .Values.image.port 9590.0 -}}
9591
{{- else -}}
9590
{{- end -}}
{{- end -}}

{{/*
Tags for the grafana dashboards
*/}}
{{- define "generic-service.dashboardTags" -}}
{{- .Release.Name | append .Values.extraDashboardTags | toJson -}}
{{- end }}

{{/*
Labels for the grafana dashboard configmaps
*/}}
{{- define "generic-service.dashboardLabels" -}}
grafana_dashboard: ""
{{ include "generic-service.labels" . }}
{{- end }}

{{/*
Generate a UID prefix for the dashboards
*/}}
{{- define "generic-service.dashboardUIDPrefix" -}}
{{- cat .Release.Namespace .Release.Name | b64enc | trunc 30 | trimSuffix "=" }}
{{- end }}

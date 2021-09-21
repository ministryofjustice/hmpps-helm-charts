{{/*
Expand the name of the chart.
*/}}
{{- define "generic-prometheus-alerts.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "generic-prometheus-alerts.fullname" -}}
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
{{- define "generic-prometheus-alerts.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "generic-prometheus-alerts.labels" -}}
{{ toYaml .Values.extraLabels }}
helm.sh/chart: {{ include "generic-prometheus-alerts.chart" . }}
{{ include "generic-prometheus-alerts.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "generic-prometheus-alerts.selectorLabels" -}}
app.kubernetes.io/name: {{ include "generic-prometheus-alerts.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Tags for the grafana dashboards
*/}}
{{- define "generic-prometheus-alerts.dashboardTags" -}}
{{- .Release.Name | append .Values.extraDashboardTags | toJson -}}
{{- end }}

{{/*
Labels for the grafana dashboard configmaps
*/}}
{{- define "generic-prometheus-alerts.dashboardLabels" -}}
grafana_dashboard: ""
{{ include "generic-prometheus-alerts.labels" . }}
{{- end }}

{{/*
Generate a UID prefix for the dashboards
*/}}
{{- define "generic-prometheus-alerts.dashboardUIDPrefix" -}}
{{- $longUID := cat .Release.Namespace .Release.Name | replace " " "" | b64enc | replace "=" "" }}
{{- regexSplit "" $longUID -1 | reverse | join "" | trunc 30 -}}
{{- end }}

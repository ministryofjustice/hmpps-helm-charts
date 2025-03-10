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
Prometheus Rule labels
*/}}
{{- define "generic-prometheus-alerts.ruleLabels" -}}
{{- $targetApplication := required "A value for targetApplication must be set" .Values.targetApplication }}
{{- $businessUnit := required "A value for businessUnit must be set" .Values.businessUnit }}
{{- $alertSeverity := required "A value for alertSeverity must be set" .Values.alertSeverity }}
{{- $environment := default "none" (.Values.global).environment -}}
{{- $productId := default "none" (.Values.global).productId -}}
{{- if .Values.additionalRuleLabels -}}
{{ toYaml .Values.additionalRuleLabels }}
{{ end -}}
severity: {{ $alertSeverity }}
application: {{ $targetApplication }}
businessUnit: {{ $businessUnit }}
environment: {{ $environment }}
productId: {{ $productId }}
{{- end }}

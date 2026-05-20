{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "envoy-forward-proxy.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "envoy-forward-proxy.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "envoy-forward-proxy.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "envoy-forward-proxy.labels" -}}
{{ include "envoy-forward-proxy.selectorLabels" . }}
app.kubernetes.io/name: {{ include "envoy-forward-proxy.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: proxy
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ include "envoy-forward-proxy.chart" . }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "envoy-forward-proxy.selectorLabels" -}}
app: {{ include "envoy-forward-proxy.fullname" . }}
release: {{ .Release.Name }}
{{- end -}}

{{/*
Extract hostname from a URL string.
Strips scheme, path, query string, fragment, and userinfo.
*/}}
{{- define "envoy-forward-proxy.hostFromUrl" -}}
{{- $url := . | toString -}}
{{- $withScheme := regexFind "https?://[^/?#]+" $url -}}
{{- if $withScheme -}}
{{- $host := trimPrefix "https://" (trimPrefix "http://" $withScheme) -}}
{{- /* Strip userinfo (user:pass@) if present */ -}}
{{- if contains "@" $host -}}
{{- $host = regexFind "[^@]+$" $host -}}
{{- end -}}
{{- $host -}}
{{- else -}}
{{- $url -}}
{{- end -}}
{{- end -}}

{{/*
Generate RBAC permissions list for the allowed hosts.
Produces a YAML list of header matchers for the :authority header.
Includes built-in defaults (AWS, Azure telemetry, service.justice.gov.uk) plus
any additional hosts specified via allowedHosts and allowedHostEnvVars.
*/}}
{{- define "envoy-forward-proxy.rbacPermissions" -}}
{{- $permissions := list -}}
{{- /* Built-in default exact hosts */ -}}
{{- $defaultExact := list "sqs.eu-west-2.amazonaws.com" "sts.eu-west-2.amazonaws.com" "agent.azureserviceprofiler.net" -}}
{{- /* Built-in default suffix hosts */ -}}
{{- $defaultSuffixes := list ".in.applicationinsights.azure.com" ".livediagnostics.monitor.azure.com" ".service.justice.gov.uk" -}}
{{- range $defaultExact }}
{{- $permissions = append $permissions (dict "header" (dict "name" ":authority" "string_match" (dict "exact" .))) -}}
{{- $permissions = append $permissions (dict "header" (dict "name" ":authority" "string_match" (dict "exact" (printf "%s:443" .)))) -}}
{{- end -}}
{{- range $defaultSuffixes }}
{{- $permissions = append $permissions (dict "header" (dict "name" ":authority" "string_match" (dict "suffix" .))) -}}
{{- $permissions = append $permissions (dict "header" (dict "name" ":authority" "string_match" (dict "suffix" (printf "%s:443" .)))) -}}
{{- end -}}
{{- /* Additional exact hosts from values */ -}}
{{- range .Values.allowedHosts.exact }}
{{- if . }}
{{- $permissions = append $permissions (dict "header" (dict "name" ":authority" "string_match" (dict "exact" .))) -}}
{{- $permissions = append $permissions (dict "header" (dict "name" ":authority" "string_match" (dict "exact" (printf "%s:443" .)))) -}}
{{- end -}}
{{- end -}}
{{- /* Additional suffix hosts from values */ -}}
{{- range .Values.allowedHosts.suffixes }}
{{- if . }}
{{- $permissions = append $permissions (dict "header" (dict "name" ":authority" "string_match" (dict "suffix" .))) -}}
{{- $permissions = append $permissions (dict "header" (dict "name" ":authority" "string_match" (dict "suffix" (printf "%s:443" .)))) -}}
{{- end -}}
{{- end -}}
{{- /* Hosts resolved from environment variable URLs */ -}}
{{- range $key := .Values.allowedHostEnvVars }}
{{- $url := index $.Values.envSource $key -}}
{{- if $url }}
{{- $host := include "envoy-forward-proxy.hostFromUrl" $url -}}
{{- $permissions = append $permissions (dict "header" (dict "name" ":authority" "string_match" (dict "exact" $host))) -}}
{{- $permissions = append $permissions (dict "header" (dict "name" ":authority" "string_match" (dict "exact" (printf "%s:443" $host)))) -}}
{{- end -}}
{{- end -}}
{{ toYaml $permissions }}
{{- end -}}

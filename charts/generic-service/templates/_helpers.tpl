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
{{- if .Values.productId }}
hmpps.justice.gov.uk/product-id: {{ .Values.productId }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "generic-service.selectorLabels" -}}
app: {{ include "generic-service.name" . }}
release: {{ .Release.Name }}
{{- end }}

{{/*
Create IP allow list annotation form nginx
*/}}
{{- define "app.makeIpAllowList" -}}
{{- $allCustomItemNames := list -}}
{{- $allGroups := list -}}
{{- $allGroupItemNames := list -}}
{{- $allAllowlists := list -}}
  {{- range $k, $v := .Values.allowlist -}}
    {{- if and (ne $k "groups") (kindIs "string" $v) -}}
      {{- $allAllowlists = append $allAllowlists $v -}}
      {{- $allCustomItemNames = append $allCustomItemNames $k -}}
    {{- end -}}
    {{- if and (eq $k "groups") ($.Values.allowlist_groups) -}}
      {{- $groups := $v -}}
      {{- range $group := $groups -}}
        {{- if not (get $.Values.allowlist_groups $group) -}}
          {{- required "Invalid group found in 'allowlist', check defined lists in 'allowlist_groups'." "" }}
        {{- end -}}
        {{- $groupList := get $.Values.allowlist_groups $group -}}
        {{- $allGroups = append $allGroups $group -}}
        {{- range $k, $v := $groupList -}}
          {{- $allGroupItemNames = append $allGroupItemNames $k -}}
          {{- $allAllowlists = append $allAllowlists $v -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{ if $allCustomItemNames -}}
  {{ cat "hmpps.justice.gov.uk/ip_allowlist_from_values:" ($allCustomItemNames | join "," | quote) }}
{{ end -}}
{{ if $allGroups -}}
  {{ cat "hmpps.justice.gov.uk/ip_allowlist_groups:" ($allGroups | join "," | quote) }}
{{ end -}}
{{ if $allGroupItemNames -}}
  {{ cat "hmpps.justice.gov.uk/ip_allowlist_from_groups:" ($allGroupItemNames | join "," | quote) }}
{{ end -}}
{{ if $.Values.allowlist_version -}}
  {{ cat "hmpps.justice.gov.uk/ip_allowlist_version:" $.Values.allowlist_version }}
{{ end -}}
{{ cat "nginx.ingress.kubernetes.io/whitelist-source-range:" ($allAllowlists | join "," | quote) }}
{{- end -}}

{{/*
Create IP allow list environment variables
*/}}
{{- define "app.makeAllowListEnvs" -}}
  {{- range $envVarName, $envVarValues := .allowlist_envs }}
  {{- $allGroups := list -}}
  {{- $allItemNames := list -}}
  {{- $allAllowlists := list -}}
    {{- range $k, $v := $envVarValues -}}
      {{- if and (ne $k "groups") (kindIs "string" $v) -}}
        {{- $allAllowlists = append $allAllowlists $v -}}
        {{- $allItemNames = append $allItemNames $k -}}
      {{- end -}}
      {{- if and (eq $k "groups") ($.allowlist_groups) -}}
        {{- $groups := $v -}}
        {{- range $group := $groups -}}
          {{- if not (get $.allowlist_groups $group) -}}
            {{- required "Invalid group found in 'allowlist', check defined lists in 'allowlist_groups'." "" }}
          {{- end -}}
          {{- $groupList := get $.allowlist_groups $group -}}
          {{- $allGroups = append $allGroups $group -}}
          {{- range $k, $v := $groupList -}}
            {{- $allItemNames = append $allItemNames $k -}}
            {{- $allAllowlists = append $allAllowlists $v -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
    {{- end }}
- name: {{ $envVarName }}
  value: {{ ($allAllowlists | join "," | quote) }}
- name: {{ $envVarName }}_NAMES
  value: {{ ($allItemNames | join "," | quote) }}
  {{- end -}}
{{- end -}}
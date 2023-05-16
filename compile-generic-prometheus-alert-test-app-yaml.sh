#!/bin/bash

set -euo pipefail

APPLICATION=${1?:No application specified}
echo "Compiling Chart YAML for $APPLICATION..."

CHART_VERSION=$(yq eval '.version' charts/generic-prometheus-alerts/Chart.yaml)
export CHART_VERSION

cd charts/generic-prometheus-alerts/ci

cd "$APPLICATION" &&
  envsubst <Chart.tpl.yaml >Chart.yaml &&
  helm dependency update

cd ..

helm template "$APPLICATION" "$APPLICATION" --dry-run --namespace "${APPLICATION}-dev" > "compiled-$APPLICATION.yaml"

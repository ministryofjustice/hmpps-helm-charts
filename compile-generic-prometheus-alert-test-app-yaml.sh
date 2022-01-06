#!/bin/bash

set -euo pipefail

echo "Compiling Chart YAML ..."

CHART_VERSION=$(yq eval '.version' charts/generic-prometheus-alerts/Chart.yaml)
export CHART_VERSION

cd charts/generic-prometheus-alerts/ci

cd test-application &&
  envsubst <Chart.tpl.yaml >Chart.yaml &&
  helm dependency update

cd ..

helm template test-application test-application --dry-run --namespace test-application-dev >compiled-yaml.yaml

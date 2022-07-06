.PHONY: build test

default: build

charts/generic-prometheus-alerts/ci/application-alerts.yaml: charts/generic-prometheus-alerts/ci/compiled-yaml.yaml
	@echo "Extracting Application Alerts ..."
	@cd charts/generic-prometheus-alerts/ci && yq eval 'select(.metadata.name == "test-application-app") | .spec' compiled-yaml.yaml > application-alerts.yaml

charts/generic-prometheus-alerts/ci/ingress-alerts.yaml: charts/generic-prometheus-alerts/ci/compiled-yaml.yaml
	@echo "Extracting Ingress Alerts ..."
	@cd charts/generic-prometheus-alerts/ci && yq eval 'select(.metadata.name == "test-application-ingress") | .spec' compiled-yaml.yaml > ingress-alerts.yaml

charts/generic-prometheus-alerts/ci/aws-rds-alerts.yaml: charts/generic-prometheus-alerts/ci/compiled-yaml.yaml
	@echo "Extracting AWS RDS Alerts ..."
	@cd charts/generic-prometheus-alerts/ci && yq eval 'select(.metadata.name == "test-application-rds") | .spec' compiled-yaml.yaml > aws-rds-alerts.yaml


charts/generic-prometheus-alerts/ci/compiled-yaml.yaml:
	@./compile-generic-prometheus-alert-test-app-yaml.sh

build: charts/generic-prometheus-alerts/ci/application-alerts.yaml charts/generic-prometheus-alerts/ci/ingress-alerts.yaml charts/generic-prometheus-alerts/ci/aws-rds-alerts.yaml

test: clean build
	promtool test rules charts/generic-prometheus-alerts/ci/tests/*.yaml

clean:
	rm -f charts/generic-prometheus-alerts/ci/compiled-yaml.yaml
	rm -f charts/generic-prometheus-alerts/ci/application-alerts.yaml
	rm -f charts/generic-prometheus-alerts/ci/ingress-alerts.yaml
	rm -f charts/generic-prometheus-alerts/ci/aws-rds-alerts.yaml
	rm -f charts/generic-prometheus-alerts/ci/test-application/Chart.lock
	rm -f charts/generic-prometheus-alerts/ci/test-application/Chart.yaml
	rm -rf charts/generic-prometheus-alerts/ci/test-application/charts

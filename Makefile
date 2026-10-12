.PHONY: build test

default: build

ci_dir="charts/generic-prometheus-alerts/ci"
objects=rules app ingress rds sns sqs opensearch
apps=test-application test-business-hours test-prod
group_names=$(foreach app,$(apps),$(addprefix $(app)-,$(objects)))

test-application-%: compiled-test-application
	@echo Extracting $@
	yq eval 'select(.metadata.name == "$@") | .spec' $(ci_dir)/$<.yaml > $(ci_dir)/$@.yaml

test-business-hours-%: compiled-test-business-hours
	@echo Extracting $@
	yq eval 'select(.metadata.name == "$@") | .spec' $(ci_dir)/$<.yaml > $(ci_dir)/$@.yaml

test-prod-%: compiled-test-prod
	@echo Extracting $@
	yq eval 'select(.metadata.name == "$@") | .spec' $(ci_dir)/$<.yaml > $(ci_dir)/$@.yaml

compiled-%:
	@./compile-generic-prometheus-alert-test-app-yaml.sh $(subst compiled-,,$@)

build: $(group_names)

test: clean build
	promtool test rules $(ci_dir)/tests/*.yaml

clean:
	rm -f $(ci_dir)/compiled-test-application.yaml
	rm -f $(ci_dir)/test-application-*.yaml
	rm -f $(ci_dir)/test-application/Chart.lock
	rm -f $(ci_dir)/test-application/Chart.yaml
	rm -rf $(ci_dir)/test-application/charts
	rm -f $(ci_dir)/compiled-test-business-hours.yaml
	rm -f $(ci_dir)/test-business-hours-*.yaml
	rm -f $(ci_dir)/test-business-hours/Chart.lock
	rm -f $(ci_dir)/test-business-hours/Chart.yaml
	rm -rf $(ci_dir)/test-business-hours/charts
	rm -f $(ci_dir)/compiled-test-prod.yaml
	rm -f $(ci_dir)/test-prod-*.yaml
	rm -f $(ci_dir)/test-prod/Chart.lock
	rm -f $(ci_dir)/test-prod/Chart.yaml
	rm -rf $(ci_dir)/test-prod/charts

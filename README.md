# HMPPS Helm Charts

Here you will find a common place for helm charts used by HMPPS projects/services.
([Click here][version_list] to see which services use them.)

The charts are built and published via GitHub Actions and GitHub pages, see <https://github.com/helm/chart-releaser>

## Making changes
Most projects will pin to a specific minor version. Patch releases should therefore be limited to bug fixes and other
new functionality that will not affect deployments.

It is important to test out any changes locally on a variety of projects prior to raising a PR.

**Worth bearing in mind when making changes** - these charts can be used by services running in clusters hosted on
CloudPlatform (#ask-cloud-platform) or Digital Studio Ops (#ask-digital-studio-ops), and they may have different
#configuration. The parameter `dso_enabled` was introduced to toggle features for services running in the DSO cluster.

Once a PR has been merged and a release created please edit the latest
[release](https://github.com/ministryofjustice/hmpps-helm-charts/releases) with information on what has changed.

## Quick start

Add new charts to `/charts` directory, create PR, once merged to `main` branch github actions will publish the chart.

Repo URL = https://ministryofjustice.github.io/hmpps-helm-charts

You can add this repo to your local helm config like this:

```
helm repo add hmpps-helm-charts https://ministryofjustice.github.io/hmpps-helm-charts
```

Search for published charts:

```
helm search repo hmpps-helm-charts
```

## Testing changes locally

To locally test how a change to this repository affects a project, instead of referencing the GitHub repo as a
dependency in that project such as:

```yaml
dependencies:
  - name: generic-service
    version: <some-version>
    repository: https://ministryofjustice.github.io/hmpps-helm-charts
```

you can reference this repository in your local file system as:

```yaml
dependencies:
  - name: generic-service
    version: <some-version>
    repository: file:///<path-to-hmpps-helm-charts>/charts/generic-service
```

Then run:

```bash
helm dependency update <directory-containing-project-chart>
```

Then can run a dry-run upgrade to see the effect:

```bash
helm upgrade \
  --dry-run \
  --namespace my-namespace \
  --values=<values-file> \
  <release-name> \
  <directory-containing-project-chart>
```
for example:
```bash
helm upgrade \
  --dry-run \
  --namespace hmpps-education-and-work-plan-dev \
  --values ./helm_deploy/values-dev.yaml \
  hmpps-education-and-work-plan-api \
  ./helm_deploy/hmpps-education-and-work-plan-api
```
You can also compare the template yaml by running the following both before and after your changes, saving the output to files:

```bash
helm template \
  --namespace my-namespace \
  --values=<values-file> \
  <release-name> \
  <directory-containing-project-chart>
```

## Unit Testing Prometheus Alerts

To run the unit tests you will need [yq], envsubst, and promtool installed, these can be installed on a Mac via homebrew:

```shell
brew install yq prometheus gettext
```

Then simply run the following to run the unit tests:

```shell
make test
```

More information on how to write a Prometheus rule unit test can be found on the Prometheus docs, see <https://www.prometheus.io/docs/prometheus/latest/configuration/unit_testing_rules/>

[version_list]: https://structurizr.com/share/56937/documentation/*#2
[yq]: https://mikefarah.gitbook.io/yq/

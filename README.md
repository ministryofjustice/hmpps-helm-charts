# HMPPS Helm Charts

Here you will find a common place for helm charts used by HMPPS projects/services.
([Click here][version_list] to see which services use them.)

The charts are built and published via github actions and github pages, see <https://github.com/helm/chart-releaser>

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

To locally test how a change to this repository affects a project, instead of referencing the GitHub repo as a dependency in that project such as:

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
    repository: file://<path-to-hmpps-helm-charts>/charts/generic-service
```

Then run:

```bash
helm dependency update <directory-containing-project-chart>
```

Then can run a dry-run upgrade to see the effect:

```bash
helm upgrade --dry-run <release-name> <directory-containing-project-chart> --values <values-file>
```

You can also compare the template yaml by running the following both before and after your changes, saving the output to files:

```bash
helm -n my-namespace template <release-name> <directory-containing-project-chart> --values=<values-file>
```

[version_list]: https://structurizr.com/share/56937/documentation/*#2

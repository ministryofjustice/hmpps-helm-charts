# HMPPS Helm Charts

Here you will find a common place for helm charts used by HMPPS projects/services.

[See the source code here](<https://github.com/ministryofjustice/hmpps-helm-charts/>)

The charts are built and published via github actions and github pages, see <https://github.com/helm/chart-releaser>

## Quick start

Add new charts to `/charts` directory, create PR, once merged to `main` branch github actions will publish the chart.

Repo URL = https://ministryofjustice.github.io/hmpps-helm-charts

You can add this repo to your local helm config like this:
```
helm repo add hmpps-helm-charts https://ministryofjustice.github.io/hmpps-helm-charts
```

Search for publish charts:

```
helm search repo hmpps-helm-charts

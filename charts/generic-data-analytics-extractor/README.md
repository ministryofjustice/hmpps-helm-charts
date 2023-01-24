# generic-data-analytics-extractor chart

This chart creates a standard cron job to extract **all data** from a postgres database and send it to an s3 bucket for analysis.

This is the final of three steps to set up daily transfers to the analytical platform as detailed in [this guide](https://dsdmoj.atlassian.net/wiki/spaces/PPDE/pages/3297050829/Steps+to+set+up+daily+transfers+to+the+analytical+platform).

Before using this chart you will need to:
- [prepare the name space](https://dsdmoj.atlassian.net/wiki/spaces/PPDE/pages/3297050829/Steps+to+set+up+daily+transfers+to+the+analytical+platform#Prepare-namespace).
- [register data with the analytical platform](https://dsdmoj.atlassian.net/wiki/spaces/PPDE/pages/3297050829/Steps+to+set+up+daily+transfers+to+the+analytical+platform#Register-data-with-the-analytical-platform).

By default we have disabled the cron job due to the Production data needing a [Data protection impact assessment](https://dsdmoj.atlassian.net/wiki/spaces/PPDE/pages/3491823875/Data+protection+impact+assessments+for+microservice+data). To override this, set `enabled: true` in you applications helm chart `values.yaml`:

```yaml
generic-data-analytics-extractor:
  enabled: true
```

## Quick Start

Add this to your project as a dependency, in your `Chart.yaml`:

```yaml
dependencies:
  - name: generic-data-analytics-extractor
    version: 0.2.0
    repository: https://ministryofjustice.github.io/hmpps-helm-charts
```

In your applications helm chart `values.yaml` add:

```yaml
generic-data-analytics-extractor:
  databaseSecretName: YOUR-DATABASE-SECRET-NAME-HERE
  analyticalPlatformSecretName: YOUR-ANALYTICAL-PLATFORM-SECRET-NAME-HERE
```

Also set any other non-default values or overrides. See available options here:

[generic-data-analytics-extractor/values.yaml](./values.yaml)

## Modifying Extractor Scripts

To modify the scripts run during the cron job you can pass in an optional `args` command e.g.:

```yaml
generic-data-analytics-extractor:
  args: YOUR-ARGS-HERE
```

Available scripts provided by the docker image can ber found in the [ministryofjustice/data-engineering-data-extractor](https://github.com/ministryofjustice/data-engineering-data-extractor) repo.
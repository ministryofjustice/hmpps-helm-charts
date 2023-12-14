# generic-data-analytics-extractor chart

This chart creates a standard cron job to extract **all data** from a postgres database and send it to an s3 bucket for analysis.

This is the final of three steps to set up daily transfers to the analytical platform as detailed in [this guide](https://dsdmoj.atlassian.net/wiki/spaces/PPDE/pages/3297050829/Steps+to+set+up+daily+transfers+to+the+analytical+platform).

Before using this chart you will need to:
- [Ensure you project is setup to use IRSA](https://user-guide.cloud-platform.service.justice.gov.uk/documentation/other-topics/access-cross-aws-resources-irsa-eks.html)
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
    version: 1.0.0
    repository: https://ministryofjustice.github.io/hmpps-helm-charts
```

In your applications helm chart `values.yaml` add:

```yaml
generic-data-analytics-extractor:
  serviceAccountName: YOUR-IRSA-ENABLED-SERVICE-ACCOUNT
  databaseSecretName: YOUR-DATABASE-SECRET-NAME-HERE
  destinationS3SecretName: YOUR-ANALYTICAL-PLATFORM-SECRET-NAME-HERE
  enabled: false
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

## Support
This helm chart was created by the HMPPS Dev teams as a convenience to make use of the Data Engineering tools to extract
data and send to the Analytical Platform.  
Whilst the docker image that the cron job uses was written by the Data Engineering team, this helm chart was created by
the HMPPS Dev teams.  
Any questions regarding the use and configuration of this helm chart should be posted on the [#hmpps_dev](https://moj.enterprise.slack.com/archives/C69NWE339)
slack channel in the first instance.
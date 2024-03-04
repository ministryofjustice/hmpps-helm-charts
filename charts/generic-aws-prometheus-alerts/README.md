# This is a Proof of concept change. Please do not use it for any live environment.

## generic-aws-prometheus-alerts chart

This chart creates a standard set of prometheus alerts for a given aws rds instance.

To receive the alerts via slack you must also set a value for `alertSeverity`. This value determines how alerts get routed to a slack channel. This is a process defined by the CloudPlatform team, see [Cloud Platform User Guide](https://user-guide.cloud-platform.service.justice.gov.uk/documentation/monitoring-an-app/how-to-create-alarms.html#creating-your-own-custom-alerts)

## Quick start

Add this to your project as a dependency chart, in your `Chart.yaml`:

```yaml
dependencies:
  - name: generic-aws-prometheus-alerts
    version: 1.0.1
    repository: https://ministryofjustice.github.io/hmpps-helm-charts
```


Also set any other non-default values or overrides. See available options here:

[generic-aws-prometheus-alerts/values.yaml](./values.yaml)

If you wish to create a new `alertSeverity` group to change which Slack channels alerts are sent to you can follow the [Cloud Platform User Guide](https://user-guide.cloud-platform.service.justice.gov.uk/documentation/monitoring-an-app/how-to-create-alarms.html#overview)

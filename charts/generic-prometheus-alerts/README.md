# generic-prometheus-alerts chart

This chart creates a standard set of prometheus alerts for a given application, and a companion grafana dashboard showing HTTP request metrics (via the NGINX ingress) and application resource (CPU/Memory) usage.

You must provide it with a value for `targetApplication`, this is used within the queries to filter results.

To receive the alerts via slack you must also set a value for `alertSeverity`. This value determines how alerts get routed to a slack channel. This is a process defined by the CloudPlatform team, see [CloudPlatform User Guide](https://user-guide.cloud-platform.service.justice.gov.uk/documentation/monitoring-an-app/how-to-create-alarms.html#creating-your-own-custom-alerts)

## Quick start

Add this to your project as a dependency chart, in your `Chart.yaml`:

```yaml
dependencies:
  - name: generic-prometheus-alerts
    version: 0.1.3
    repository: https://ministryofjustice.github.io/hmpps-helm-charts
```

in your applications helm chart `values.yaml` add:

```yaml
generic-prometheus-alerts:
  targetApplication: YOUR-APP-NAME-HERE
  alertSeverity: AS-GIVEN-BY-CLOUDPLATFORMS
```

Also set any other non-default values or overrides. See available options here:

[generic-prometheus-alerts/values.yaml](./values.yaml)

# generic-prometheus-alerts chart

This chart creates a standard set of prometheus alerts for a given application.

## Breaking change (major upgrade)

From `2.0.0` onwards, `alertSeverity` is deprecated and must be removed from consumer values files.

If `alertSeverity` is still set, chart rendering will fail with a deprecation message.

### Required team actions

- Remove `alertSeverity` from your chart values.
- Ensure these repository variables are set with appropriate values, for example the Slack channel where alerts are sent (do not include a preceding `#`; a Slack ID is also valid, as well as the Slack channel name):
  - `PROD_ALERTS_SLACK_CHANNEL`
  - `NONPROD_ALERTS_SLACK_CHANNEL`

Alert routing depends on repository variables. You must ensure these are set with appropriate values, for example the Slack channel where alerts are sent (do not include a preceding `#`; a Slack ID is also valid, as well as the Slack channel name):

- `PROD_ALERTS_SLACK_CHANNEL`
- `NONPROD_ALERTS_SLACK_CHANNEL`

Alert delivery and forwarding now works as follows:

- Alerts are first delivered to centrally managed Slack channels:
  - `#hmpps-prometheus-alerts-prod`
  - `#hmpps-prometheus-alerts-nonprod`
- Alerts are then forwarded to the relevant team alerting channel by the hmpps-slack-relay-bot.
- The relay bot determines the correct app/environment/channel mapping from Developer Portal (Service Catalogue) data.

For context, this chart still uses an alert `severity` label to split prod/non-prod routing:

- `prod` or `production` -> `hmpps_alerts_prod`
- any other value (or unset) -> `hmpps_alerts_nonprod`

This severity-based routing is MoJ-specific behavior which enables routing alert messages based on an existing label.

## Quick start

Add this to your project as a dependency chart, in your `Chart.yaml`:

```yaml
dependencies:
  - name: generic-prometheus-alerts
    version: 2.0.0
    repository: https://ministryofjustice.github.io/hmpps-helm-charts
```

in your applications helm chart `values.yaml` add:

```yaml
generic-prometheus-alerts:
  targetApplication: YOUR-APP-NAME-HERE
```

You must provide a value for `targetApplication`. This is used within alert queries to filter results.

Also set any other non-default values or overrides. See available options here:

[generic-prometheus-alerts/values.yaml](./values.yaml)

`global.environment` is set by the shared GitHub Actions deploy job and controls production vs non-production routing.

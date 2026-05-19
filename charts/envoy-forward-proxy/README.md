# Envoy Forward Proxy Helm Chart

A Helm chart for deploying an [Envoy](https://www.envoyproxy.io/) forward proxy that uses HTTP CONNECT tunnelling to proxy HTTPS traffic. This is useful for proxying outbound HTTPS connections from applications that need to reach external services (e.g. Azure Application Insights, AWS SQS, HMPPS Auth).

## Overview

This chart deploys:

- **Deployment**: An Envoy proxy configured as a forward HTTPS proxy using CONNECT tunnelling with dynamic forward proxy DNS resolution.
- **Service**: A ClusterIP service exposing the proxy port within the namespace.
- **ConfigMap**: The Envoy configuration including RBAC rules to restrict which upstream hosts are allowed.

## Usage

Add this chart as a dependency in your application's `Chart.yaml`:

```yaml
dependencies:
  - name: envoy-forward-proxy
    version: "1.0"
    repository: https://ministryofjustice.github.io/hmpps-helm-charts
```

Then configure it in your `values.yaml`:

```yaml
envoy-forward-proxy:
  enabled: true
  # Additional hosts beyond the built-in defaults
  allowedHosts:
    exact:
      - agent.azureserviceprofiler.net
    suffixes:
      - .example.com
```

The chart includes the following hosts by default (always included, additive with your configuration):
- **Exact**: `sqs.eu-west-2.amazonaws.com`, `sts.eu-west-2.amazonaws.com`, `agent.azureserviceprofiler.net`
- **Suffixes**: `.in.applicationinsights.azure.com`, `.livediagnostics.monitor.azure.com`, `.service.justice.gov.uk`

You can also resolve hostnames dynamically from environment variable URLs:

```yaml
envoy-forward-proxy:
  allowedHostEnvVars:
    - MY_API_URL
  envSource:
    MY_API_URL: "https://my-api.example.com"
```

Then configure your application to use the proxy. The service name will be `<release>-envoy-forward-proxy` by default; use `fullnameOverride` to set a fixed name:

```yaml
envoy-forward-proxy:
  fullnameOverride: envoy-https-proxy

generic-service:
  env:
    HTTP_PROXY: "http://envoy-https-proxy:3128"
    HTTPS_PROXY: "http://envoy-https-proxy:3128"
    NO_PROXY: "localhost,127.0.0.1,envoy-https-proxy"
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `enabled` | Whether to deploy the envoy proxy | `true` |
| `nameOverride` | Override the chart name | `""` |
| `fullnameOverride` | Override the full resource name | `""` |
| `replicas` | Number of proxy replicas | `2` |
| `logLevel` | Envoy log level | `info` |
| `image.repository` | Envoy image repository | `envoyproxy/envoy` |
| `image.tag` | Envoy image tag | `v1.38-latest` |
| `ports.proxy` | Proxy listener port | `3128` |
| `ports.admin` | Admin interface port | `9901` |
| `resources` | Container resource requests/limits | See `values.yaml` |
| `allowedHosts.exact` | Additional exact hostnames to allow (on top of built-in defaults) | `[]` |
| `allowedHosts.suffixes` | Additional hostname suffixes to allow (on top of built-in defaults) | `[]` |
| `allowedHostEnvVars` | Env var names whose URL values should be allowed | `[]` |
| `envSource` | Map of env var name to URL value for resolving `allowedHostEnvVars` | `{}` |
| `dns.lookupFamily` | DNS lookup family | `V4_ONLY` |
| `dns.hostTtl` | DNS host TTL | `300s` |
| `connectTimeout` | Upstream connect timeout | `10s` |

## How It Works

The proxy uses Envoy's HTTP CONNECT tunnelling feature with a dynamic forward proxy cluster. When a client sends a CONNECT request, Envoy:

1. Checks the `:authority` header against the RBAC allow list
2. If allowed, resolves the upstream host via DNS
3. Establishes a TCP tunnel to the upstream host on port 443

This allows applications to make HTTPS requests through the proxy without the proxy needing to terminate TLS.

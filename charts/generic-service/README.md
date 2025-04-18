# Generic-service helm chart

## Prerequisites

### 1. Helm v3 client

This is installed and used within our circleci pipelines but it is also useful to have installed locally for troubleshooting. See <https://helm.sh/docs/intro/install/>

### 2. A namespace in Cloudplatform cluster

See guide here for more details: <https://user-guide.cloud-platform.service.justice.gov.uk/documentation/getting-started/env-create.html#creating-a-cloud-platform-environment>

See example kubernetes namespace files here: <https://github.com/ministryofjustice/cloud-platform-environments/tree/main/namespaces/live-1.cloud-platform.service.justice.gov.uk/digital-prison-services-dev>

### 3. HTTPS certificate for ingress resource

In addition to namespace above - ensure a valid LetsEncrypt TLS cert has been generated by CloudPlatform's certbot. Official instructions here <https://user-guide.cloud-platform.service.justice.gov.uk/documentation/other-topics/custom-domain-cert.html#obtaining-a-certificate>.

Example here: <https://github.com/ministryofjustice/cloud-platform-environments/blob/main/namespaces/live-1.cloud-platform.service.justice.gov.uk/digital-prison-services-dev/07-certificates.yaml>

### 4. Kubernetes secrets

If the application needs to access secrets as part of the deployment these must be loaded into Cloudplatforms kubernetes cluster prior to deployment.

See official guide here: <https://user-guide.cloud-platform.service.justice.gov.uk/documentation/deploying-an-app/add-secrets-to-deployment.html>

Also, see example below.

## How to use this chart

Each project should define an umbrella chart, in most cases this will be essentially an empty helm chart, which specifies this chart as a dependancy.

File/folder structure as follows, with more details below on file contents:

```bash
helm_deploy
helm_deploy/values-[environment].yaml (1 per environment)
helm_deploy/[project name]
helm_deploy/[project name]/Chart.yaml
helm_deploy/[project name]/.helmignore
helm_deploy/[project name]/values.yaml

helm_deploy/[project name]/templates/ (* optional)
```

(_* optionally include the `templates/` folder containing project specific resources not installed by generic-service chart e.g. cronjobs_)

Example `Chart.yaml`

```yaml
apiVersion: v2
appVersion: "1.0"
description: A Helm chart for Kubernetes
name: [PROJECT NAME HERE]
version: 0.1.0

dependencies:
  - name: generic-service
    version: 1.0.5
    repository: https://ministryofjustice.github.io/hmpps-helm-charts
```

### Setting project wide values

`helm_deploy/[project name]/values.yaml`

The values here override the default values set in the `generic-service` chart - see the _values.yaml_ in this repo/folder.

This file will contain values that are the same across all environments.

Example project `values.yaml` file:

```yaml
---
generic-service:
  nameOverride: project-name

  image:
    repository: quay.io/hmpps/project-name
    port: 8080

  ingress:
    enabled: true
    tlsSecretName: [name of secret for ingress TLS cert]
    path: /

  # Environment variables to load into the deployment
  env:
    JAVA_OPTS: "-Xmx512m"
    SERVER_PORT: "8080"
    SPRING_PROFILES_ACTIVE: "logstash"
    APPLICATIONINSIGHTS_CONNECTION_STRING: "InstrumentationKey=$(APPINSIGHTS_INSTRUMENTATIONKEY)"

  # Pre-existing kubernetes secrets to load as environment variables in the deployment.
  # namespace_secrets:
  #   [name of kubernetes secret]:
  #     [name of environment variable as seen by app]: [key of kubernetes secret to load]

  namespace_secrets:
    project-name:
      APPINSIGHTS_INSTRUMENTATIONKEY: "APPINSIGHTS_INSTRUMENTATIONKEY"
      AP_ARN: "arn?" # optional

  # Pre-existing kubernetes secrets to load as mounted file(s) within pod/container
```

### Mounting Secrets

[K8s documentation to mount secrets](https://kubernetes.io/docs/concepts/configuration/secret/#use-case-dotfiles-in-a-secret-volume)

```yaml
  volumes:
    - name: secrets
      secret:
        secretName: "k8s-secret-name"
        items:
          - key: secret-key
            path: secret-file-name
  volumeMounts:
    - name: secrets
      mountPath: /app/secrets
      readOnly: true
```

This configuration will create a file `/app/secrets/secret-file-name` with the content of the k8s secret within it.

When loading secrets as mounted volumes inside a container the pre-existing kubernetes secret should look like the following, as per example above:

```yaml
kind: Secret
type: Opaque
apiVersion: v1
data:
  secret-key: [base64 encoded file contents]
```

### Injecting env into batch yamls

You can inject the set of environment variables defined for the pods into other application yamls such as batch jobs:

`{{- include "deployment.envs" (index .Values "generic-service") | nindent 12 }}`

### Setting environment specific values

`helm_deploy/values-[environment].yaml`

This file should only contain values that differ between environments.

Example of `helm_deploy/values-[environment].yaml` file:

```yaml
---
generic-service:
  replicaCount: 2

  ingress:
    hosts:
      - project-name-dev.hmpps.service.justice.gov.uk
```

### Prison Postgres database restore cronjob
The NOMIS pre-production database gets refreshed from production approximately every two weeks.  It is normally a good
idea to copy the other Prison databases at the same time so that the pre-production environment is in sync.
Setting
```yaml
---
postgresDatabaseRestore:
  enabled: true
```
in your `values-prod.yaml`
will create a scheduled job runs every four hours in production only.  This checks to see if there is a newer version of
the NOMIS database since the last database restore and if so then does another restore.  The pre-production credentials
should be injected into the production namespace, see https://github.com/ministryofjustice/cloud-platform-environments/pull/8325
for an example PR. Both production and pre-production credentials should then be added as a `namespace_secrets:` section,
see the `values.yaml` in this repository for an example of the secrets and other options.

Currently, Flyway and ActiveRecord database migrations are supported. The default is Flyway. You can change this by
supplying the `MIGRATIONS_VENDOR` environment variable in the `env:` section (see `values.yaml` for an example). Possible 
values are `flyway` and `active_record`.

If you have set up a schema separate to the default 'public' schema and want to refresh that schema, you must additionally
supply the `SCHEMA_TO_RESTORE` environment variable in the `env:` section (again see the `values.yaml` for an example).
If you have additionally set up a separate (non-admin) user to access this schema you may find that after refresh the permissions
on tables etc for that user are reset. A simple way to resolve this is to issue the following one-off database command in a console:

```sql
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA <SCHEMA_TO_RESTORE> TO <NON_ADMIN_USER_NAME>;
ALTER DEFAULT PRIVILEGES IN SCHEMA <SCHEMA_TO_RESTORE> GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO <NON_ADMIN_USER_NAME>;
```


#### Inputs

| Name     | Description                                                                                                                                                                                 | Example     |
|----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| timeout  | Sets the active deadline seconds after which the job will be terminated and the Job status will become `type: Failed` with `reason: DeadlineExceeded`. Default is 2400 seconds (40 minutes) | 7200        |
| schedule | Overrides the default cron schedule (30 6-21/4 * * 1-5) allowing preprod databases which are up continuously to be restored as soon as possible after Nomis is restored                     | 5 */2 * * * |

#### Manually running the database restore cronjob
The restore cronjob script only runs if there is a newer NOMIS database so we need to override the configuration to ensure to force the run.
We do that by using `jq` to amend the json and adding in the `FORCE_RUN=true` parameter.

```shell
kubectl create job --dry-run=client --from=cronjob/hmpps-nomis-visits-mapping-service-postgres-restore hmpps-nomis-visits-mapping-service-postgres-restore-<user> -o "json" | jq ".spec.template.spec.containers[0].env += [{ \"name\": \"FORCE_RUN\", \"value\": \"true\"}]" | kubectl apply -f -
```
will trigger the job to dump the production database and import into pre-production.
Job progress can then be seen by running `kubectl logs -f` on the newly created pod.

The last successful restore information is stored in a `restore_status` table in pre-production.
To find out when the last restore ran connect to the pre-production database and view the contents of the table.

### Scheduled downtime

For cost saving purposes, MOJ Cloud Platform provides an option to shut down RDS databases overnight in non-production
environment.
[Check the user guide for more information](https://user-guide.cloud-platform.service.justice.gov.uk/documentation/deploying-an-app/relational-databases/create.html#non-production).

In addition to shutting down the database, this chart also provides an option to schedule shutdown and startup of pods.

#### Service Account

To enable this feature, you first need to add a `scheduled-downtime-serviceaccount` Service Account to your namespace,
with permissions to scale your deployment.

Example: [scheduled-downtime.tf](https://github.com/ministryofjustice/cloud-platform-environments/blob/23fdd1a1b13e1ede43f778b7be6c8765939f27a0/namespaces/live.cloud-platform.service.justice.gov.uk/hmpps-probation-integration-services-dev/resources/scheduled-downtime.tf)

```terraform
module "scheduled_downtime_service_account" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-serviceaccount?ref=0.8.1"

  namespace          = var.namespace
  kubernetes_cluster = var.kubernetes_cluster

  serviceaccount_name  = "scheduled-downtime-serviceaccount"
  role_name            = "scheduled-downtime-serviceaccount-role"
  rolebinding_name     = "scheduled-downtime-serviceaccount-rolebinding"
  serviceaccount_rules = [
    {
      api_groups = ["apps"]
      resources  = ["deployments"]
      verbs      = ["get"]
    },
    {
      api_groups = ["apps"]
      resources  = ["deployments/scale"]
      verbs      = ["get", "update", "patch"]
    }
  ]
}
```

#### Configuration values

Once you have a service account, add the following to your `values-dev.yaml` and `values-preprod.yaml` to enable the
cron jobs:

```yaml
scheduledDowntime:
  enabled: true
```

By default, this will shut down pods between 10pm - 6:30am UTC on weekdays and all day on weekends.
6:30am was chosen as the RDS startup happens between 6am and 6:30am
To change this schedule, update the `startup` and `shutdown` values:

```yaml
---
scheduledDowntime:
  enabled: true
  startup: '0 6 * * 1-5' # Start at 6am UTC Monday-Friday
  shutdown: '0 22 * * 1-5' # Stop at 10pm UTC Monday-Friday
  timeZone: Etc/UTC
  serviceAccountName: scheduled-downtime-serviceaccount # This must match the service account name in the Terraform module
```

### Retrying messages on a dead letter queue

The [hmpps-spring-boot-sqs](https://github.com/ministryofjustice/hmpps-spring-boot-sqs/?tab=readme-ov-file#usage) project provides an endpoint for retrying all messages on all dead letter queues. Setting the following value will add a cronjob to your service which will call the retry endpoint every 10 minutes. 

```yaml
---
retryDlqCronjob:
  enabled: true
  retryDlqSchedule: "*/20 * * * *" # only set this if you want to override the default schedule of every 10 minutes
```

If you have configured scheduled downtime, the cronjob will not run during the downtime
Again, you can override the default cron schedule when scheduled downtime is enabled:

```yaml
---
scheduledDowntime:
  retryDlqSchedule: "*/45 * * * 1-3"
```

# ClamAV Helm Chart

This helm chart installs the following kubernetes resources:

***Service***: provides the main entry point for application to access the `clamd` deamon, e.g. _tcp://clamav:3310_

***Deployment***: includes an _initContainer_ which runs `freshclam` prior to starting the main _clamd_ container, this ensures antivirus database is up-to-date. The antivirus DB is saved to an emptyDir volume, which is mounted by all containers in the pod.

***CronJob***: The job re-deploys the above deployment on the schedule specified.  This pulls the latest image, which includes an up-to-date antivirus database. Note: requires service account with necessary permissions to restart. The ClamAV image repo is here: <https://github.com/ministryofjustice/hmpps-utility-container-images>

## Issues

Freshclam has been removed from this chart - due to problems with rate limiting on the offical clamav database. This is due to the increased number of clamav instances inside the CP cluster, and that the official database.clamav.net runs very strict http rate limits. The new plan is to build a fresh up-to-date clamav image everyday - and have the deployment pull the latest image everyday via the cronjob.

## Checking if the AV DB is up-to-date

The normal way for `freshclam` to get it's updates is to query a DNS txt record, e.g.

```bash
$ host -t txt current.cvd.clamav.net;
current.cvd.clamav.net descriptive text "0.102.1:59:25680:1577795340:1:63:49191:331"
```

...from the output here we can see that `25680` is the latest version of the daily.cvd database that is available. 

This should chacked against the running version which can be done like this:

```bash
kubectl -n [namespace] exec -it clamav-7b9b698c77-cd9xh -c clamd -- clamd --version
```

### Setup

A service account must be created in order to use this chart. There are two options to achieve this:
1. create a PR in cloud platform environments adding [this file](https://github.com/ministryofjustice/cloud-platform-environments/blob/main/namespaces/live.cloud-platform.service.justice.gov.uk/hmpps-document-management-dev/resources/serviceaccount-refreshclamav.tf) to the namespace.
2. The circleci service account in the namespace must have the permissions to handle reading/writing serviceaccounts and set the `createServiceAccount` value to true in the helm deploy

Installation:

```bash
helm --namespace [namespace] install clamav ./clamav --values=values.yaml
```

Upgrade:

```bash
helm --namespace [namespace] upgrade clamav ./clamav --values=values.yaml
```

Manually test cronjob refresh of data:

```bash
kubectl -n [namespace] create job testingrefresh --from=cronjob/refresh-clamav-db
```

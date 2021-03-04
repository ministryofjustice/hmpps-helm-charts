# ClamAV Helm Chart

This helm chart installs the following kubernetes resources:

***Service***: provides the main entry point for application to access the `clamd` deamon, e.g. _tcp://clamav:3310_

***Deployment***: includes an _initContainer_ which runs `freshclam` prior to starting the main _clamd_ container, this ensures antivirus database is up-to-date. The antivirus DB is saved to an emptyDir volume, which is mounted by all containers in the pod.

***CronJob***: The job re-deploys the above deployment on the schedule specified.  This refreshes the antivirus database.  Note: requires service account with necessary permissions to restart.

## Why a CronJob?

Under normal circumstances we would run both `clamd` and `freshclam` in the background, and let `freshclam` periodically update the AV data. `clamd` daemon will periodically check if the AV data has been updated and then reload the data into memory.  The problem is that during this reload `clamd` becomes unresponsive for approx 30-40s.

To get around this issue, and to keep with best practice of running only one process in a container, this deployment runs an initContainer which run `freshclam` and then runs `clamd` in the main container spec.

Importantly, because we have the _RollingUpdate_ strategy (maxSurge: 100%, maxUnavailable: 0) - we can avoid any downtime.  Kubernetes will spin up the new pod and ensure it's running before terminating the old.

## Issues

Currently there are two init containers in the deployment - there is a problem or bug with the way clamav applies/distributes updates. The normal way for freshclam to get it's updates is to query a DNS txt record, e.g.

```bash
$ host -t txt current.cvd.clamav.net;
current.cvd.clamav.net descriptive text "0.102.1:59:25680:1577795340:1:63:49191:331"
```

...from the output here we can see that `25680` is the latest version of the daily.cvd database. However when `freshclam` is running against a completely empty DB folder e.g. for the first time - it downloads the latest version available of the `daily.cvd` file. Once downloaded it checks the version against the DNS txt record version. This is where it fails and reports out of sync - this is because the downloaded file is often the previous version.  This could be due to a stale cache issue at cloudflare (CDN used by clamav), or maybe some latency in building and releasing the latest version `daily.cvd` in line with DNS txt record update.

To get round this, we run `freshclam --no-dns`, which skips the DNS query and heads straight for the lastest available to download.  Then run `freshclam` again (using DNS version checking), which then downloads an incremental patch and applies it.

Checking the version of the DB can be done like this:

```bash
kubectl -n [namespace] exec -it clamav-7b9b698c77-cd9xh -c clamd -- clamd --version
```

Checking the logs from the init containers:

```bash
kubectl -n [namespace] logs clamav-7b9b698c77-cd9xh -c initfreshclam
kubectl -n [namespace] logs clamav-7b9b698c77-cd9xh -c init2freshclam
```

### Setup

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

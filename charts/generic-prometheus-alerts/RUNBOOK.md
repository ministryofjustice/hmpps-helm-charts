# Generic Prometheus Alerts Runbook

This page contains notes detailing what the alerts contained in this chart mean and what you can (and should) do to follow up on them should they fire in your project...

## Ingress Alerts

### ingress-5xx-error-responses

> Ingress `<namespace>`/`<service>` is serving 5xx responses.

Your application has been responding with regular 5xx status codes for over 1 minute.

The best course of action is to check your application logs or error tracking system (i.e. Application Insights or Sentry) and investigate the issue from there.

### ingress-rate-limiting

> Rate limit is being applied on ingress `<namespace>`/`<service>`.

The NGINX ingress has been limiting requests to your application for over 1 minute. This is most likely due to a sudden jump in traffic to your application (i.e. a denial of service attack).

The best course of action is to check the application and ingress logs and investigate the issue from there.

### ingress-modsecurity-blocking

> Mod_Security is blocking ingress `<namespace>`/`<service>`. Blocking http requests at rate of `<rate>` per minute.

The modsecurity module (part of the NGINX ingress) has been blocking requests to your application at an elevated rate for over 1 minute. This is most likely due to the modsecurity rules detecting what it deem malicious requests.

The best course of action is to check the ingress logs and investigate the issue from there.

## Application Alerts

### application-pod-crashlooping

> Pod `<namespace>`/`<pod>` (`<container>`) is restarting `<rate>` times every 5 minutes.

One of your application pods/containers has been crashing and restarting more that `<rate>` times every 5 minutes for the last 15 minutes. This indicates that there is a serious issue with the application or its configuration.

The best course of action is to first check the events for the pod, you will find them at the bottom of the pod description:

```
kubectl -n <namespace> describe pod <pod>
```

If there are no clear errors or failures there check the logs for that specific pod/container either in the logging service or via:

```
kubectl -n <namespace> logs <pod> -c <container>
```

### application-pod-notready

> Pod `<namespace>`/`<pod>` has been in a non-ready state for longer than 15 minutes.

One of your pods has been failing its "readiness" check for over 15 minutes.

The best course of action is to check the pod logs and investigate the issue from there.

```
kubectl -n <namespace> logs <pod>
```

### application-deployment-generation-mismatch

> Deployment generation for `<namespace>`/`<deployment>` does not match, this indicates that the Deployment has failed but has not been rolled back.

### application-deployment-replicas-mismatch

> Deployment `<namespace>`/`<deployment>` has not matched the expected number of replicas for longer 15 minutes.

### application-container-waiting

> Pod `<namespace>`/`<pod>` container `<container>` has been in waiting state for longer than 1 hour.

This could indicate a capacity issue on the kubernetes cluster. Speak to the cloud platform team as soon as possible.

### application-cronjob-running

> CronJob `<namespace>`/`<cronjob>` is taking more than 1h to complete.

You'll need to look at the logs from the pods which this cronjob was running to investigate the issues. The following commands (substituting in the namespace and cronjobjob name) will give you the logs from the last running pod from the cronjob:

```
job=$(kubectl -n <namespace> get job --sort-by=.metadata.creationTimestamp | grep <cronjob> | awk '{ print $1 }' | tail -n 1)
pod=$(kubectl -n <namespace> get pods --selector=job-name=${job} --sort-by=.metadata.creationTimestamp --output=jsonpath='{.items[-1].metadata.name}')
kubectl -n <namespace> logs $pod
```

### application-job-completion

> Job `<namespace>`/`<job>` is taking more than six hours to complete.

You'll need to look at the logs from the pods which this job was running to investigate the issues. The following commands (substituting in the namespace and job name) will give you the logs for the last running pod for the job:

```
pod=$(kubectl -n <namespace> get pods --selector=job-name=<job> --sort-by=.metadata.creationTimestamp --output=jsonpath='{.items[-1].metadata.name}')
kubectl -n <namespace> logs $pod
```

### application-job-failed

> Job `<namespace>`/`<job>` failed to complete.

You'll need to look at the logs from the pods which this job was running to investigate the issues. You can do this using the logging service or with a couple of commands like so (substituting in the namespace and job name):

```
pods=$(kubectl -n <namespace> get pods --selector=job-name=<job> --output=jsonpath='{.items[*].metadata.name}')
kubectl -n <namespace> logs $pods
```

### application-hpa-replicas-mismatch

> HPA `<namespace>`/`<hpa>` has not matched the desired number of replicas for longer than 15 minutes.

Your HPA has not managed to start the desired number of replicas of your application. This could indicate a capacity issue on the kubernetes cluster. Speak to the cloud platform team as soon as possible.

### application-hpa-maxed-out

> HPA `<namespace>`/`<hpa>` has been running at max replicas for longer than 15 minutes.

Your replica count defined in your HPA has been at its maximum for over 15 minutes, indicating that your service is under heavy load and could need to be resized.

Check your application metrics to see your resource usage profile and request metrics. If this is not a "one off" situation, look at increasing the maximum number of replicas allowed in your HPA.

### application-quota-exceeded

> Namespace `<namespace>` is using `<percentage>` of its `<resource>` quota.

Your namespace is using a large percentage of one of the pre-defined quotas.

If you genuinely need more capacity on this quota, speak to the cloud platform team.

### application-container-oom-killed

> Container `<container>` in pod `<namespace>`/`<pod>` has been OOM Killed (out of memory) `XX` times in the last 10 minutes.

Your application container is using more memory than it's currently configured to be allowed to so kubernetes is killing and restarting it.

If your application genuinely needs more memory you can either set memory requests and limits in your application helm chart - this will affect only your container/pod - or you can also increase the default requests and limits for all pods in your namespace by editing the `limitrange` in your namespace (via [cloud-platform-environments](https://github.com/ministryofjustice/cloud-platform-environments)).

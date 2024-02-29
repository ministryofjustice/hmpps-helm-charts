# Generic Prometheus Alerts for AWS RDS Runbook

This page contains notes detailing what the alerts contained in this chart mean and what you can (and should) do to follow up on them should they fire in your project...

## RDS Alerts

### rds-cpu-utilisation

> RDS database `<database>` in `<namespace>` - CPU utilisation at `XX` which is over threshold of `YY` for last 5 mins.

Database CPU utilisation being too high for long periods of time suggests either that your database is missing indices
or that you might need to consider using a bigger database instance class.

If your database is expected to run hot then you could always increase `rdsAlertsCPUThreshold` to a higher value.

### rds-connection-count

> RDS database `<database>` in `<namespace>` - there are `XX` connections which is over threshold of `YY` for last 5 mins.

Your connection pools should be configured so that your database doesn't run out of connections.

AWS cloudwatch doesn't expose the maximum number of connections, so this needs to be calculated.
[DBInstanceClass](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.DBInstanceClass.html) contains information on how
much memory each instance class has e.g. db.t3.small is 2Gib, db.t3.medium is 4GiB.
[RDS_Limits.MaxConnections](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Limits.html#RDS_Limits.MaxConnections) then provides
calculations for each database on the maximum number of database connections so for a `db.t3.small database` it will be
```
LEAST({2Gib/9531392}, 5000) = LEAST({2 * 1024 * 1024 * 1024/9531392}, 5000) = LEAST(225, 5000) = 225
```

So if you're running a `db.t3.small` postgres database and if you're configured 8 pods, each allowing 30 connections 
= 240 connections then you'll run out.

The alert should be configured so that it alerts for about 80% utilisation, so it could be that you need to set
`rdsAlertsConnectionThreshold` to a more suitable value.

Other reasons why you could run out is if perhaps you're running r2dbc and you've got a connection leak caused by a
[bug](https://github.com/r2dbc/r2dbc-pool/issues/165).


PRISON_API_BASE_URL=https://prison-api-preprod.prison.service.justice.gov.uk

DB_NAME=dbb58b51dd02b491a0
DB_HOST=cloud-platform-b58b51dd02b491a0.cdwm328dlye6.eu-west-2.rds.amazonaws.com
DB_USER=cpYHgphGY9
DB_PASS=vgyS6OIGF6qzMXgI

DB_NAME_PREPROD=dbecaa06ca3b89ae46
DB_HOST_PREPROD=cloud-platform-ecaa06ca3b89ae46.cdwm328dlye6.eu-west-2.rds.amazonaws.com
DB_USER_PREPROD=cpCDOVLUH0
DB_PASS_PREPROD=1z5cBebCPINqFaIU


# grab last restore details from Prison API
DATABASE_RESTORE_INFO=$(check_http GET "$PRISON_API_BASE_URL/api/restore-info")
if ! DATABASE_RESTORE_JSON=$(check_http GET "$PRISON_API_BASE_URL/api/restore-details"); then
  echo -e "\nUnable to find any restore information."
  if [[ -z "${FORCE_RUN+x}" ]]; then
    echo -e "\nTo force a run set the FORCE_RUN environment variable when creating the job (see README.md in hmpps-helm-charts/generic-service)"
    echo "DATABASE_RESTORE_JSON"
    exit 0
  fi
  echo -e "\nRun forced"
  DATABASE_RESTORE_DATE=$(date +%F) # default to current date
  DATABASE_BACKUP_TIMESTAMP=$(date +'%FT%T') # default to current datetime
  DATABASE_RESTORE_TIMESTAMP=$DATABASE_BACKUP_TIMESTAMP
else
  DATABASE_RESTORE_DATE=$(echo "$DATABASE_RESTORE_INFO" | jq -r .)
  DATABASE_BACKUP_TIMESTAMP=$(echo $DATABASE_RESTORE_JSON | jq -r .backup)
  DATABASE_RESTORE_TIMESTAMP=$(echo $DATABASE_RESTORE_JSON | jq -r .restore)
fi

# Check that we can connect to preprod postgres and create restore table
if ! OUTPUT=$(psql_preprod "create table if not exists ${SCHEMA_TO_RESTORE:+${SCHEMA_TO_RESTORE}.}restore_status(restore_date date)"); then
  echo -e "\nUnable to talk to postgres and create restore table"
  echo "$OUTPUT"
  exit 1
fi
# Add timestamp columns if not there and initialise
psql_preprod "alter table ${SCHEMA_TO_RESTORE:+${SCHEMA_TO_RESTORE}.}restore_status add column if not exists backup_timestamp timestamp"
psql_preprod "alter table ${SCHEMA_TO_RESTORE:+${SCHEMA_TO_RESTORE}.}restore_status add column if not exists restore_timestamp timestamp"
psql_preprod "update ${SCHEMA_TO_RESTORE:+${SCHEMA_TO_RESTORE}.}restore_status set restore_timestamp = now() where restore_timestamp is null"

# Grab last restore info from postgres. The 'to_json' conversions ensure we get ISO timestamps with a 'T'
SAVED_TIMES=$(psql_preprod "select restore_date, to_json(restore_timestamp)#>>'{}', to_json(backup_timestamp)#>>'{}'
  from ${SCHEMA_TO_RESTORE:+${SCHEMA_TO_RESTORE}.}restore_status")
IFS='|' read SAVED_RESTORE_DATE SAVED_RESTORE_TIMESTAMP SAVED_BACKUP_TIMESTAMP <<< $SAVED_TIMES

# we've found a date, check to see if we've had a newer restore
# Try the new timestamp-based refresh criterion, and revert to the old if it fails
if [[ -n "$SAVED_RESTORE_TIMESTAMP" ]]; then
  if [[ ! $DATABASE_RESTORE_TIMESTAMP > $SAVED_RESTORE_TIMESTAMP ]]; then
    echo -e "\nExisting Postgres restore time of $SAVED_RESTORE_TIMESTAMP is no older than Nomis restore at $DATABASE_RESTORE_TIMESTAMP"
    if [[ -z "${FORCE_RUN+x}" ]]; then
      echo -e "\nTo force a run set the FORCE_RUN environment variable when creating the job (see README.md in hmpps-helm-charts/generic-service)"
      exit 0
    fi
    echo -e "\nRun forced"
  fi
elif [[ -n $SAVED_RESTORE_DATE && ! $DATABASE_RESTORE_DATE > $SAVED_RESTORE_DATE ]]; then
  echo -e "\nExisting restore date of $SAVED_RESTORE_DATE is no older than $DATABASE_RESTORE_DATE"
  if [[ -z "${FORCE_RUN+x}" ]]; then
    echo -e "\nTo force a run set the FORCE_RUN environment variable when creating the job (see README.md in hmpps-helm-charts/generic-service)"
    exit 0
  fi
  echo -e "\nRun forced"
fi

# Grab schema versions from preprod and prod.  If schema history different then restore won't really work
# Only solution is to release to production before then doing the restore.
MIGRATIONS_VENDOR="${MIGRATIONS_VENDOR:-flyway}"
if [[ "$MIGRATIONS_VENDOR" == "flyway" ]]; then
  SCHEMA_VERSIONS_SQL="select count(version) from ${SCHEMA_TO_RESTORE:+${SCHEMA_TO_RESTORE}.}flyway_schema_history"
elif [[ "$MIGRATIONS_VENDOR" == "active_record" ]]; then
  SCHEMA_VERSIONS_SQL="select count(version) from ${SCHEMA_TO_RESTORE:+${SCHEMA_TO_RESTORE}.}schema_migrations"
elif [[ "$MIGRATIONS_VENDOR" == "alembic" ]]; then
  SCHEMA_VERSIONS_SQL="select version_num from ${ALEMBIC_SCHEMA:+${ALEMBIC_SCHEMA}.}alembic_version"
elif [[ "$MIGRATIONS_VENDOR" == "knex" ]]; then
  SCHEMA_VERSIONS_SQL="select count(name) from ${SCHEMA_TO_RESTORE:+${SCHEMA_TO_RESTORE}.}knex_migrations"
else
  echo -e "\nUnrecognized MIGRATIONS_VENDOR value: $MIGRATIONS_VENDOR. Valid values are 'flyway', 'alembic' or 'active_record'"
  exit 1
fi

PREPROD_SCHEMA_VERSION=$(psql_preprod "$SCHEMA_VERSIONS_SQL")
PROD_SCHEMA_VERSION=$(psql_prod "$SCHEMA_VERSIONS_SQL")
if [[ "$PREPROD_SCHEMA_VERSION" != "$PROD_SCHEMA_VERSION" ]]; then
  echo -e "\nFound different number of schema versions"
  echo "Preprod has $PREPROD_SCHEMA_VERSION different versions"
  echo "Prod has $PROD_SCHEMA_VERSION different versions"
  echo "SQL used for comparison was: $SCHEMA_VERSIONS_SQL"
  exit 1
else
  echo -e "\n$MIGRATIONS_VENDOR migrations check passed, both schemas have $PROD_SCHEMA_VERSION versions installed"
fi

# Retrieve the postgres database production backup
aws s3 cp s3://$BUCKET_NAME/db.dump /tmp/db.dump
# TODO: check age of backup vs DATABASE_BACKUP_TIMESTAMP ?

# Restore database to preprod
pg_restore -h "$DB_HOST_PREPROD" -U "$DB_USER_PREPROD" ${SCHEMA_TO_RESTORE:+-n $SCHEMA_TO_RESTORE} --clean --if-exists --no-owner --single-transaction -v -d "$DB_NAME_PREPROD" /tmp/db.dump

# now stash away the restore status in postgres
echo -e "\nWriting DATABASE_RESTORE_DATE = $DATABASE_RESTORE_DATE, DATABASE_BACKUP_TIMESTAMP = $DATABASE_BACKUP_TIMESTAMP, DATABASE_RESTORE_TIMESTAMP = $DATABASE_RESTORE_TIMESTAMP to the preprod database"
psql_preprod "delete from ${SCHEMA_TO_RESTORE:+${SCHEMA_TO_RESTORE}.}restore_status"
psql_preprod "insert into ${SCHEMA_TO_RESTORE:+${SCHEMA_TO_RESTORE}.}restore_status (restore_date,backup_timestamp, restore_timestamp) values ('$DATABASE_RESTORE_DATE','$DATABASE_BACKUP_TIMESTAMP', '$DATABASE_RESTORE_TIMESTAMP')"

# Delete the backup
aws s3 rm s3://$BUCKET_NAME/db.dump

echo -e "\nRestore successful"

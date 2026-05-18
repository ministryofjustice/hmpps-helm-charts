
PRISON_API_BASE_URL=https://prison-api-preprod.prison.service.justice.gov.uk

# grab last restore details from Prison API
if ! DATABASE_RESTORE_JSON=$(check_http GET "$PRISON_API_BASE_URL/api/restore-details"); then
  echo -e "\nUnable to find any restore information."
  if [[ -z "${FORCE_RUN+x}" ]]; then
    echo -e "\nTo force a run set the FORCE_RUN environment variable when creating the job (see README.md in hmpps-helm-charts/generic-service)"
    echo "$DATABASE_RESTORE_JSON"
    exit 0
  fi
  echo -e "\nRun forced"
  DATABASE_BACKUP_TIMESTAMP=$(date +'%FT%T') # default to current datetime
  DATABASE_RESTORE_TIMESTAMP=$DATABASE_BACKUP_TIMESTAMP
else
  DATABASE_BACKUP_TIMESTAMP=$(echo $DATABASE_RESTORE_JSON | jq -r .backup)
  DATABASE_RESTORE_TIMESTAMP=$(echo $DATABASE_RESTORE_JSON | jq -r .restore)
fi

echo -e "Obtained database restore details:\n$DATABASE_RESTORE_JSON"

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
SAVED_TIMES=$(psql_preprod "select to_json(restore_timestamp)#>>'{}', to_json(backup_timestamp)#>>'{}'
  from ${SCHEMA_TO_RESTORE:+${SCHEMA_TO_RESTORE}.}restore_status")
IFS='|' read SAVED_RESTORE_TIMESTAMP SAVED_BACKUP_TIMESTAMP <<< $SAVED_TIMES

# we've found a date, check to see if we've had a newer restore
if [[ -n "$SAVED_RESTORE_TIMESTAMP" && ! $DATABASE_RESTORE_TIMESTAMP > $SAVED_RESTORE_TIMESTAMP ]]; then
  echo -e "\nExisting Postgres restore time of $SAVED_RESTORE_TIMESTAMP is no older than Nomis restore at $DATABASE_RESTORE_TIMESTAMP"
  if [[ -z "${FORCE_RUN+x}" ]]; then
    echo -e "\nTo force a run set the FORCE_RUN environment variable when creating the job (see README.md in hmpps-helm-charts/generic-service)"
    exit 0
  fi
  echo -e "\nRun forced"
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

FALLBACK=""
if [[ -z "$BUCKET_NAME" ]]; then
  echo "BUCKET_NAME not defined so falling back to dumping prod now"
  FALLBACK=true
else
  POSTGRES_BACKUP_DATE=$(aws s3api head-object --bucket "$BUCKET_NAME" --key rds-backup/db.dump | jq -r .Metadata.created | cut -c 1-10)
  NOMIS_BACKUP_DATE=$(echo $DATABASE_BACKUP_TIMESTAMP | cut -c 1-10)

  # Check that the postgres backup we are using is the right one. We are not too fussy, the right date is good enough.
  if [[ "$POSTGRES_BACKUP_DATE" != "$NOMIS_BACKUP_DATE" ]]; then
    echo "s3 backup create date $POSTGRES_BACKUP_DATE does not match nomis backup at $DATABASE_BACKUP_TIMESTAMP, falling back to dumping prod now"
    FALLBACK=true
  else
    echo "s3 backup create date $POSTGRES_BACKUP_DATE matches nomis backup at $DATABASE_BACKUP_TIMESTAMP"
    # Retrieve the postgres database production backup
    if ! aws s3 cp s3://$BUCKET_NAME/rds-backup/db.dump /tmp/db.dump; then
      echo "s3 backup retrieval failed, falling back to dumping prod now"
      FALLBACK=true
    fi
  fi
fi
if [[ -n "$FALLBACK" ]]; then
  pg_dump -h "$DB_HOST" -U "$DB_USER" ${SCHEMA_TO_RESTORE:+-n $SCHEMA_TO_RESTORE} -Fc --no-privileges -v --file=/tmp/db.dump "$DB_NAME"
fi

# Restore database to preprod
pg_restore -h "$DB_HOST_PREPROD" -U "$DB_USER_PREPROD" ${SCHEMA_TO_RESTORE:+-n $SCHEMA_TO_RESTORE} --clean --if-exists --no-owner --single-transaction -v -d "$DB_NAME_PREPROD" /tmp/db.dump

# now stash away the restore status in postgres
echo -e "\nWriting DATABASE_BACKUP_TIMESTAMP = $DATABASE_BACKUP_TIMESTAMP, DATABASE_RESTORE_TIMESTAMP = $DATABASE_RESTORE_TIMESTAMP to the preprod database"
psql_preprod "delete from ${SCHEMA_TO_RESTORE:+${SCHEMA_TO_RESTORE}.}restore_status"
psql_preprod "insert into ${SCHEMA_TO_RESTORE:+${SCHEMA_TO_RESTORE}.}restore_status (backup_timestamp, restore_timestamp) values ('$DATABASE_BACKUP_TIMESTAMP', '$DATABASE_RESTORE_TIMESTAMP')"

# Delete the backup
aws s3 rm s3://$BUCKET_NAME/rds-backup/db.dump

echo -e "\nRestore successful"

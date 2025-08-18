#!/bin/bash
set -ue

PRISON_API_BASE_URL=https://prison-api-preprod.prison.service.justice.gov.uk

check_http() { http --stream --check-status --ignore-stdin --timeout=600 "$@"; }
psql_preprod() { psql -h "$DB_HOST_PREPROD" -U "$DB_USER_PREPROD" -d "$DB_NAME_PREPROD" -At -c "$@"; }
psql_prod() { psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -At -c "$@"; }

# grab last restore date from Prison API
if ! DATABASE_RESTORE_INFO=$(check_http GET "$PRISON_API_BASE_URL/api/restore-info"); then
  echo -e "\nUnable to find any restore information."
  if [[ -z "${FORCE_RUN+x}" ]]; then
    echo -e "\nTo force a run set the FORCE_RUN environment variable when creating the job (see README.md in hmpps-helm-charts/generic-service)"
    echo "$DATABASE_RESTORE_INFO"
    exit 0
  fi
  echo -e "\nRun forced"
  DATABASE_RESTORE_DATE=$(date +%F) # default to current date
else
  DATABASE_RESTORE_DATE=$(echo "$DATABASE_RESTORE_INFO" | jq -r .)
fi

echo "${DB_HOST}:5432:${DB_NAME}:${DB_USER}:${DB_PASS}" > ~/.pgpass
echo "${DB_HOST_PREPROD}:5432:${DB_NAME_PREPROD}:${DB_USER_PREPROD}:${DB_PASS_PREPROD}" >> ~/.pgpass
chmod 0600 ~/.pgpass

# Check postgres server versions and adjust PATH to use the correct version of pg client tools.
PSQL_PREPROD_VERSION=$(psql_preprod "SHOW server_version;" | cut -d"." -f1)
PSQL_PROD_VERSION=$(psql_preprod "SHOW server_version;" | cut -d"." -f1)
if [[ "$PSQL_PREPROD_VERSION" != "$PSQL_PROD_VERSION" ]]; then
  echo "Preprod and prod postgres server versions are different"
  echo "Preprod version: $PSQL_PREPROD_VERSION"
  echo "Prod version: $PSQL_PROD_VERSION"
  exit 1
fi
echo "Detected PostgreSQL server version: $PSQL_PROD_VERSION"

# Set the path to the specific version of psql
PSQL_PATH="/usr/lib/postgresql/$PSQL_PROD_VERSION/bin"
if [[ -d "$PSQL_PATH" ]]; then
  export PATH="$PSQL_PATH:$PATH"
  echo "Set PATH to: $PATH"
else
  echo "Path $PSQL_PATH does not exist"
  exit 1
fi

# Check that we can connect to preprod postgres and create restore table
if ! OUTPUT=$(psql_preprod "create table if not exists ${SCHEMA_TO_RESTORE:+${SCHEMA_TO_RESTORE}.}restore_status(restore_date date)"); then
  echo -e "\nUnable to talk to postgres and create restore table"
  echo "$OUTPUT"
  exit 1
fi

# Grab last restore date from postgres
SAVED_RESTORE_DATE=$(psql_preprod "select restore_date from ${SCHEMA_TO_RESTORE:+${SCHEMA_TO_RESTORE}.}restore_status")

# we've found a date, check to see if we've had a newer restore
if [[ -n $SAVED_RESTORE_DATE && ! $DATABASE_RESTORE_DATE > $SAVED_RESTORE_DATE ]]; then
  echo -e "\nExisting restore date of $SAVED_RESTORE_DATE no newer than $DATABASE_RESTORE_DATE"
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

# Dump postgres database from production
pg_dump -h "$DB_HOST" -U "$DB_USER" ${SCHEMA_TO_RESTORE:+-n $SCHEMA_TO_RESTORE} -Fc --no-privileges -v --file=/tmp/db.dump "$DB_NAME"

# Restore database to preprod
pg_restore -h "$DB_HOST_PREPROD" -U "$DB_USER_PREPROD" ${SCHEMA_TO_RESTORE:+-n $SCHEMA_TO_RESTORE} --clean --if-exists --no-owner --single-transaction -v -d "$DB_NAME_PREPROD" /tmp/db.dump

# now stash away the restore status in postgres
echo -e "\nWriting restore date of $DATABASE_RESTORE_DATE to the preprod database"
psql_preprod "delete from restore_status"
psql_preprod "insert into restore_status (restore_date) values ('$DATABASE_RESTORE_DATE')"
echo -e "\nRestore successful"

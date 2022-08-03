#!/bin/bash
set -e

PRISON_API_BASE_URL=https://api-preprod.prison.service.justice.gov.uk

check_http() { http --stream --check-status --ignore-stdin --timeout=600 "$@"; }
psql_preprod() { psql -h "$DB_HOST_PREPROD" -U "$DB_USER_PREPROD" -d "$DB_NAME_PREPROD" -At -c "$@"; }

# grab last restore date from Prison API
if ! DATABASE_RESTORE_INFO=$(check_http GET "$PRISON_API_BASE_URL/api/restore-info"); then
  echo -e "\nUnable to find any restore information."
  if [[ -z "$FORCE_RUN" ]]; then
    echo -e "\nTo force a run set the FORCE_RUN environment variable when creating the job (see README.md in hmpps-helm-charts/generic-service)"
    echo "$DATABASE_RESTORE_INFO"
    exit 0
  else
    echo -e "\nRun forced"
  fi
fi
DATABASE_RESTORE_DATE=$(echo "$DATABASE_RESTORE_INFO" | jq -r .)

echo "${DB_HOST}:5432:${DB_NAME}:${DB_USER}:${DB_PASS}" > ~/.pgpass
echo "${DB_HOST_PREPROD}:5432:${DB_NAME_PREPROD}:${DB_USER_PREPROD}:${DB_PASS_PREPROD}" >> ~/.pgpass
chmod 0600 ~/.pgpass

# Check that we can connect to preprod postgres and create restore table
if ! OUTPUT=$(psql_preprod "create table if not exists restore_status(restore_date date)"); then
  echo -e "\nUnable to talk to postgres and create restore table"
  echo "$OUTPUT"
  exit 1
fi

# Grab last restore date from postgres
SAVED_RESTORE_DATE=$(psql_preprod "select restore_date from restore_status")

# we've found a date, check to see if we've had a newer restore
if [[ -n $SAVED_RESTORE_DATE && ! $DATABASE_RESTORE_DATE > $SAVED_RESTORE_DATE ]]; then
  echo -e "\nExisting restore date of $SAVED_RESTORE_DATE no newer than $DATABASE_RESTORE_DATE"
  if [[ -z "$FORCE_RUN" ]]; then
    echo -e "\nTo force a run set the FORCE_RUN environment variable when creating the job (see README.md in hmpps-helm-charts/generic-service)"
    exit 0
  else
    echo -e "\nRun forced"
  fi
fi

# Dump postgres database from production
pg_dump -h $DB_HOST -U $DB_USER -Fc --no-privileges -v --file=/tmp/db.dump $DB_NAME

# Restore database to preprod
pg_restore -h $DB_HOST_PREPROD -U $DB_USER_PREPROD --clean --no-owner -v -d $DB_NAME_PREPROD /tmp/db.dump

if [[ -z "$FORCE_RUN" ]]; then
  # now stash away the restore status in postgres
  echo -e "\nWriting restore date of $DATABASE_RESTORE_DATE to the preprod database"
  psql_preprod "delete from restore_status"
  psql_preprod "insert into restore_status (restore_date) values ('$DATABASE_RESTORE_DATE')"
else
  echo -e "\nNot writing restore date to database as FORCE_RUN was specified"
fi
echo -e "\nRestore successful"


check_http() { http --stream --check-status --ignore-stdin --timeout=600 "$@"; }
psql_preprod() { psql -h "$DB_HOST_PREPROD" -U "$DB_USER_PREPROD" -d "$DB_NAME_PREPROD" -At -c "$@"; }
psql_prod() { psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -At -c "$@"; }

echo "${DB_HOST}:5432:${DB_NAME}:${DB_USER}:${DB_PASS}" > ~/.pgpass
echo "${DB_HOST_PREPROD}:5432:${DB_NAME_PREPROD}:${DB_USER_PREPROD}:${DB_PASS_PREPROD}" >> ~/.pgpass
chmod 0600 ~/.pgpass

# Check postgres server versions and adjust PATH to use the correct version of pg client tools.
PSQL_PREPROD_VERSION=$(psql_preprod "SHOW server_version;" | cut -d"." -f1)
PSQL_PROD_VERSION=$(psql_prod "SHOW server_version;" | cut -d"." -f1)
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

# Grab schema versions from preprod and prod.  If schema history different then backup and restore won't really work
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

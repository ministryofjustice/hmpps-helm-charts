
# Dump postgres database from production
if ! pg_dump -h "$DB_HOST" -U "$DB_USER" ${SCHEMA_TO_RESTORE:+-n $SCHEMA_TO_RESTORE} -Fc --no-privileges -v --file=/tmp/db.dump "$DB_NAME"; then
  echo -e "\nUnable to talk to postgres"
  exit 1
fi

NOW=$(date +%Y-%m-%dT%H:%M:%S)
EXPIRE=$(date +%Y-%m-%dT%H:%M:%S --date "+ 60 day")

# Save to S3 bucket, overwriting any old backup
aws s3 cp /tmp/db.dump s3://$BUCKET_NAME/rds-backup/db.dump --metadata created=$NOW --expires $EXPIRE

echo -e "\nBackup successful"

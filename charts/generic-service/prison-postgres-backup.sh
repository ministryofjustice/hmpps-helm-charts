
BUCKET_NAME=cloud-platform-6fa48239f03bad709e6347c565328b76

# Dump postgres database from production
if ! pg_dump -h "$DB_HOST" -U "$DB_USER" ${SCHEMA_TO_RESTORE:+-n $SCHEMA_TO_RESTORE} -Fc --no-privileges -v --file=/tmp/db.dump "$DB_NAME"; then
  echo -e "\nUnable to talk to postgres"
  exit 1
fi

# Save to S3 bucket, overwriting any old backup
aws s3 cp /tmp/db.dump s3://$BUCKET_NAME/db.dump

echo -e "\nBackup successful"

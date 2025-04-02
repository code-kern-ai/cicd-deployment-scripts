# !/bin/bash
set -e

PG_HOST=""
PG_USER=""
PG_PASSWORD=""
PG_DATABASE=""
PG_DUMP_NAME=""

RESOURCE_GROUP_NAME=""
STORAGE_ACCOUNT_NAME=""
FILE_SHARE_NAME=""


while getopts h:u:d:n:p:r:s:f: flag
do
    case "${flag}" in
        h) PG_HOST=${OPTARG};;
        u) PG_USER=${OPTARG};;
        d) PG_DATABASE=${OPTARG};;
        n) PG_DUMP_NAME=${OPTARG};;
        p) PG_PASSWORD=${OPTARG};;
        r) RESOURCE_GROUP_NAME=${OPTARG};;
        s) STORAGE_ACCOUNT_NAME=${OPTARG};;
        f) FILE_SHARE_NAME=${OPTARG};;
    esac
done

# environment variables used to authenticate and configure the postgresql client
# https://www.postgresql.org/docs/8.4/libpq-envars.html
export PGHOST=$PG_HOST
export PGUSER=$PG_USER
export PGPASSWORD=$PG_PASSWORD

pg_dump --dbname $PG_DATABASE --file pg_dump_${PG_DATABASE}_${PG_DUMP_NAME} --format=d --jobs 2

echo "PG_DUMP_PATH=$(pwd)/pg_dump_${PG_DATABASE}_${PG_DUMP_NAME}" >> $GITHUB_OUTPUT

# STORAGE_ACCOUNT_KEY=$(su - ${admin_username} -c "az storage account keys list \
#     --resource-group $RESOURCE_GROUP_NAME \
#     --account-name $STORAGE_ACCOUNT_NAME \
#     --query '[0].value' --output tsv | tr -d '\"'")
# az storage file upload-batch \
#     --destination ${FILE_SHARE_NAME} \
#     --destination-path pg_dump/${PG_DATABASE}/${PG_DUMP_NAME} \
#     --source pg_dump_${PG_DATABASE}_${PG_DUMP_NAME} \
#     --account-key $STORAGE_ACCOUNT_KEY

# !/bin/bash
set -e

PG_HOST=""
PG_USER=""
PG_PASSWORD=""
PG_DATABASE=""
PG_DUMP_PATH=""

while getopts h:u:d:n:p: flag
do
    case "${flag}" in
        h) PG_HOST=${OPTARG};;
        u) PG_USER=${OPTARG};;
        d) PG_DATABASE=${OPTARG};;
        n) PG_DUMP_PATH=${OPTARG};;
        p) PG_PASSWORD=${OPTARG};;
    esac
done

# environment variables used to authenticate and configure the postgresql client
# https://www.postgresql.org/docs/8.4/libpq-envars.html
export PGHOST=$PG_HOST
export PGUSER=$PG_USER
export PGPASSWORD=$PG_PASSWORD

# terminate existing and block new connections to the database
psql --command "REVOKE CONNECT ON DATABASE $PG_DATABASE FROM PUBLIC, $PG_USER;"
psql --command "SELECT pg_terminate_backend(pid) \
FROM pg_stat_activity \
WHERE pid <> pg_backend_pid() AND datname = '$PG_DATABASE';
"

dropdb $PG_DATABASE
createdb $PG_DATABASE

pg_restore --dbname $PG_DATABASE ${PG_DUMP_PATH} --format=d --jobs 2
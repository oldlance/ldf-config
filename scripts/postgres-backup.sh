#!/usr/bin/env bash
#
# postgres-backup.sh
# -----------------
# Script to backup postgres database data, schema and configuration
# to disk.  Databases to be backed up are specifed in array ${dbso[]}
#
# Needs to be run as root
#
set -euo pipefail

log () {
  local msg="${1:-}"
  echo "[$(date -Iseconds)] $msg"
}

bin_dir=/usr/local/bin
script_basename=$(basename "$0")
script_name=$(basename -s .sh "$script_basename")
db_user=postgres
backups_dir=/usr/local/var/backups/postgres

# Add databases to backup to this array
#dbs=(airflow movie_plots companies_house cwphase3)
dbs=(airflow chatgpt_login companies_house cwphase3 forms_dev hello_dev live_view_studio_2ed_dev movie_plots template_tutorial uk_co_basic_dev)

log "starting $script_name ..."

log "back up config files to $backups_dir"
cp /var/db/postgres/data17/conf.d/*.conf "$backups_dir"/
cp /var/db/postgres/data17/*.conf "$backups_dir"/

log "backup up globals to $backups_dir/postgres-globals.sql"
"$bin_dir"/pg_dumpall -U $db_user --globals-only -f "$backups_dir"/postgres-globals.sql

for db in "${dbs[@]}" ; do

  log "starting to back up $db ..."

  log "  backing up $db schema to $backups_dir/$db-schema.sql ..."
  "$bin_dir"/pg_dump -U $db_user --create --format=plain --schema-only -f "$backups_dir"/"$db"-schema.sql  "$db"

  log "  backing up $db data to $backups_dir/$db-data.dmp.pg ..."
  "$bin_dir"/pg_dump -U $db_user --format=custom -f "$backups_dir"/"$db"-data.dmp.pg  "$db"

  log "... $db done"

done

log "completed $script_name"



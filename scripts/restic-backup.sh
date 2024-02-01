#!/usr/bin/env bash
#
# restic-backup.sh
# ----------------
# This script uses restic to backup local data.  It requires an external configuration file in which the following
# environment variables are defined.  If not specified, it will used /usr/local/etc/restic-backup/restic-backup.conf
#     RETENTION_LAST  
#     RETENTION_DAYS
#     RETENTION_WEEKS
#     RETENTION_MONTHS
#     RETENTION_YEARS
#
#     GOOGLE_PROJECT_ID
#     GOOGLE_APPLICATION_CREDENTIALS
#
#     RESTIC_REPOSITORY
#     RESTIC_PASSWORD
#
#     LOCAL_BACKUPS_DIR
#
# Should be run as root.
#
set -euo pipefail


log () {
  local msg="${1:-}"
  echo "[$(date -Iseconds)] $msg"
}

if [[ $EUID -ne 0 ]]; then
  log "ERROR: $0 must be run as root; consider using 'sudo'."
  exit 2
fi

bin_dir=/usr/local/bin
script_basename=$(basename "$0")
script_name=$(basename -s .sh "$script_basename")
script_conf="${1:-/usr/local/etc/$script_name/$script_name.conf}"
script_config_dir=$(dirname "$script_conf")

if [ ! -e "$script_conf" ] ; then
  echo "Aborting as script configuration file '$script_conf' cannot be found."
  echo "Usage: $script_basename <script-config-file-path>"
  echo ""
  exit 1
fi

# shellcheck source=/usr/local/etc/restic-backup/restic-backup.conf
source "$script_conf"

log "================ starting $script_name with config file $script_conf ..."

# Export the latest list of installed packages, both bare and with origins.
if [ -d "${LOCAL_BACKUPS_DIR:-}" ] ; then
  /usr/sbin/pkg prime-list | sort > "$LOCAL_BACKUPS_DIR"/pkg-prime-list
  /usr/sbin/pkg prime-origins | sort > "$LOCAL_BACKUPS_DIR"/pkg-prime-origins
fi

log "++++++++++++++++ backing up ..."
"$bin_dir"/restic backup \
	--verbose \
	--tag periodic \
	--exclude-file="$script_config_dir"/exclude-from-backup \
	--files-from="$script_config_dir"/include-in-backup

log "---------------- pruning ..."
"$bin_dir"/restic forget \
        --verbose \
	--tag periodic \
	--group-by "paths,tags" \
	--keep-last "$RETENTION_LAST" \
	--keep-daily "$RETENTION_DAYS" \
	--keep-weekly "$RETENTION_WEEKS" \
	--keep-monthly "$RETENTION_MONTHS" \
	--keep-yearly "$RETENTION_YEARS" \
	--prune

log "................ completed $script_name"

#!/usr/bin/env bash
#
# resticctl.sh
# ----------------
# This is a convenience script for executing restic without having to enter
# the repo and password every time.
#
# It requires, /usr/local/etc/resticctl/resticctl.conf, in which the following
# environment variables are defined.
#
#     GOOGLE_PROJECT_ID
#     GOOGLE_APPLICATION_CREDENTIALS
#
#     RESTIC_REPOSITORY
#     RESTIC_PASSWORD
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
script_conf=/usr/local/etc/"$script_name"/"$script_name".conf

if [ ! -e "$script_conf" ] ; then
  echo "Aborting as script configuration file '$script_conf' cannot be found."
  echo "Usage: $script_basename <script-config-file-path>"
  echo ""
  exit 1
fi

# shellcheck source=/usr/local/etc/resticctl/resticctl.conf
source "$script_conf"

log "Repository: $RESTIC_REPOSITORY"

"$bin_dir"/restic  "$@"

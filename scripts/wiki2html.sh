#!/usr/bin/env bash
#
set -euo pipefail

HOME_DIR="$HOME/Development/misaka_md2html"

pushd "$HOME_DIR" >>/dev/null

#echo "Args: $@"

source bin/activate

./misaka_md2html.py "$@"

popd >> /dev/null


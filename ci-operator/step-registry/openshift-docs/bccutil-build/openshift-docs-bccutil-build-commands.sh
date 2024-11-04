#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail
set -o verbose

ccutil compile --lang=en-US --format html-single

mkdir "${ARTIFACT_DIR}/bccutil-build"

find "${ARTIFACT_DIR}" -type d -exec sh -c '
  for FOLDER in "$@"; do
    if [ -f "$FOLDER/master.adoc" ]; then
      cd "$FOLDER"

      ccutil compile --lang=en-US --format html-single

      cp -r . "${ARTIFACT_DIR}/bccutil-build"
    fi
  done
' sh {} +

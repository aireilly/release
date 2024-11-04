#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail
set -o verbose
# Enable tracing
set -x

curl https://raw.githubusercontent.com/openshift/openshift-docs/main/scripts/get-updated-portal-books.sh > scripts/get-updated-portal-books.sh

NETLIFY_AUTH_TOKEN=$(cat /tmp/vault/ocp-docs-netlify-secret/NETLIFY_AUTH_TOKEN)

export NETLIFY_AUTH_TOKEN

COMMIT_ID=$(git log -n 1 --pretty=format:"%H")
PULL_NUMBER="$(curl -s "https://api.github.com/search/issues?q=$COMMIT_ID" | jq '.items[0].number')"

mkdir -p ${ARTIFACT_DIR}/bccutil-netlify

# Deploy with netlify
find "${ARTIFACT_DIR}" -type d -exec sh -c '
  for FOLDER in "$@"; do
    if [ -d $FOLDER/build/tmp/en-US/html-single ]; then
      TARGET_DIR="$(basename $FOLDER)"
      mkdir ${ARTIFACT_DIR}/${JOB_NAME}/${BUILD_ID}/bccutil-netlify/${TARGET_DIR}
      cp -r $FOLDER/build/tmp/en-US/html-single ${ARTIFACT_DIR}/${JOB_NAME}/${BUILD_ID}/bccutil-netlify/${TARGET_DIR}
    fi
  done
' sh {} +

netlify deploy --site "${PREVIEW_SITE}" --auth "${NETLIFY_AUTH_TOKEN}" --alias "${PULL_NUMBER}" --dir="${ARTIFACT_DIR}/bccutil-netlify"
#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail
set -o verbose

curl https://raw.githubusercontent.com/openshift/openshift-docs/main/scripts/get-updated-distros.sh > scripts/get-updated-distros.sh

IFS=' ' read -r -a DISTROS <<< "${DISTROS}"

PREVIEW_URL="https://${PULL_NUMBER}--${PREVIEW_SITE}.netlify.app"

for DISTRO in "${DISTROS[@]}"; do

    case "${DISTRO}" in
        "openshift-enterprise"|"openshift-acs"|"openshift-pipelines"|"openshift-serverless"|"openshift-gitops"|"openshift-builds"|"openshift-service-mesh"|"openshift-opp"|"openshift-rhde"|"openshift-lightspeed")
            TOPICMAP="_topic_maps/_topic_map.yml"
            ;;
        "openshift-rosa")
            TOPICMAP="_topic_maps/_topic_map_rosa.yml"
            ;;
        "openshift-rosa-hcp")
            TOPICMAP="_topic_maps/_topic_map_rosa_hcp.yml"
            ;;
        "openshift-dedicated")
            TOPICMAP="_topic_maps/_topic_map_osd.yml"
            ;;
        "microshift")
            TOPICMAP="_topic_maps/_topic_map_ms.yml"
            ;;
    esac

    ./scripts/get-updated-distros.sh | while read -r FILENAME; do
        if [ "${FILENAME}" == "${TOPICMAP}" ]; then
            echo -e "\e[91mBuilding openshift-docs with ${DISTRO} distro...\e[0m"
            python3 "${BUILD}" --distro "${DISTRO}" --product "OpenShift Container Platform" --version "${VERSION}" --no-upstream-fetch
        elif [ "${FILENAME}" == "_distro_map.yml" ]; then
            python3 "${BUILD}" --distro "openshift-enterprise" --product "OpenShift Container Platform" --version "${VERSION}" --no-upstream-fetch
        fi
    done
done

if [ -d "drupal-build" ]; then
    mkdir -p ${ARTIFACT_DIR}/bccutil-portal
    python3 makeBuild.py

    # Copy only the updated book folders from drupal-build/
    scripts/get-updated-portal-books.sh | while read -r FILENAME; do
        FOLDER_PATH=$(dirname "${FILENAME}")

        if [[ "$FOLDER_PATH" == "." ]]; then
            continue
        fi

        cp -r ${FOLDER_PATH} ${ARTIFACT_DIR}/bccutil-portal
    done
fi

# Calculate the portal preview URLs
scripts/get-updated-portal-books.sh | while read -r FILENAME; do
    # Log the calculated URL to UPDATED_PAGES
    echo "$FILENAME" | cut -d'/' -f3- | sed 's/\master.adoc$/html-single\/index.html/' | sed "s|^|$PREVIEW_URL/|" | tr '\n' ' ' >> "${SHARED_DIR}/UPDATED_PAGES"
done
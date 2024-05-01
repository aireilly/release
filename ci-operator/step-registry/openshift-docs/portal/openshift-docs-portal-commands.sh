#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail
set -o verbose

IFS=' ' read -r -a DISTROS <<< "${DISTROS}"

for DISTRO in "${DISTROS[@]}"; do

    case "${DISTRO}" in
        "openshift-enterprise"|"openshift-acs"|"openshift-pipelines"|"openshift-serverless"|"openshift-gitops"|"openshift-builds"|"openshift-service-mesh"|"openshift-opp"|"openshift-rhde")
            TOPICMAP="_topic_maps/_topic_map.yml"
            ;;
        "openshift-rosa")
            TOPICMAP="_topic_maps/_topic_map_rosa.yml"
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
            python3 "${BUILD}" --distro "${DISTRO}" --product "OpenShift Container Platform" --version "${VERSION}" --no-upstream-fetch | tee /dev/stderr | grep -o "ERROR" && exit 1 || echo "Finished"
        elif [ "${FILENAME}" == "_distro_map.yml" ]; then
            python3 "${BUILD}" --distro "openshift-enterprise" --product "OpenShift Container Platform" --version "${VERSION}" --no-upstream-fetch | tee /dev/stderr | grep -o "ERROR" && exit 1 || echo "Finished"
        fi
    done
done

if [ -d "drupal-build" ]; then
    python3 makeBuild.py | tee /dev/stderr | grep -o "ERROR" && exit 1 || echo "Finished"
fi
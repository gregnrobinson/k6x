#!/bin/bash
set -o errexit
set -o pipefail

export CLOUDSDK_CORE_DISABLE_PROMPTS="1"
export SHORT_SHA="$(git rev-parse --short HEAD)"
export GCP_SA_JSON=$(find ./config/creds/*.json)

gcloud auth activate-service-account --key-file=${GCP_SA_JSON}

environment() {
    yq e '.substitutions._SHORT_SHA |= env(SHORT_SHA) | .substitutions._SHORT_SHA style="double"' -i ./image/cloudbuild.yaml
    IMG_DEST=$(yq e '.environment.img_dest' settings.yaml) yq e '.substitutions._IMG_DEST |= env(IMG_DEST) | .substitutions._IMG_DEST style="double"' -i ./image/cloudbuild.yaml
}

build(){
    environment
    gcloud components install cloud-build-local -q
    gcloud components update cloud-build-local -q

    gcloud builds submit \
        --config ./image/cloudbuild.yaml
}

run(){
    logo=$(tput setaf 6)
    warn=$(tput setaf 3)
    bold=$(tput bold)
    normal=$(tput sgr0)
    
    BRANCH="$(git branch --show-current)"

    LOGO="$(wget -q -O /tmp/logo artii.herokuapp.com/make?text=k6x&font=small)"
    LOGO="$(cat /tmp/logo)"
    rm -rf /tmp/logo

    echo "${logo}${LOGO}${normal}"
    echo "${logo}Version: ${BRANCH}-${SHORT_SHA}${normal}"

    LOGGED_IN=$(gcloud auth list 2>&1)

    if [[ $LOGGED_IN == *"Listed 0 items"* ]]; then
        echo "GCP login required..."
        gcloud auth login --no-launch-browser
    else
        echo "building..."
        build
    fi
}

run


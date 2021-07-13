#!/bin/bash
set -o errexit
set -o pipefail

export CLOUDSDK_CORE_DISABLE_PROMPTS="1"
export SHORT_SHA="$(git rev-parse --short HEAD)"
export PROJECT_ID=$(gcloud config list --format 'value(core.project)')
export IMG_DEST="gcr.io/${PROJECT_ID}/k6x"

yaml_substitutions(){
    echo "Setting up inventory files..."
}

build(){
    yaml_substitutions

    gcloud components install cloud-build-local -q
    gcloud components update cloud-build-local -q

    gcloud builds submit\
    --substitutions=_IMG_DEST=$IMG_DEST,_SHORT_SHA=$SHORT_SHA \
    --config ./image/cloudbuild_local.yaml
}

run(){
    logo=$(tput setaf 6)
    warn=$(tput setaf 3)
    bold=$(tput bold)
    normal=$(tput sgr0)
    
    BRANCH="$(git branch --show-current)"

    LOGO="$(wget -q -O /tmp/logo artii.herokuapp.com/make?text=Docker+Builder&font=small)"
    LOGO="$(cat /tmp/logo)"
    rm -rf /tmp/logo

    echo "${logo}${LOGO}${normal}"
    echo "${logo}Version: ${BRANCH}-${SHORT_SHA}${normal}"
    
    if [ -z "$PROJECT_ID" ]; then 
        printf 'Enter a Project ID (ctrl^c to exit): '
        read -r PROJECT_ID
    fi

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


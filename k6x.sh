#!/bin/bash
set -o errexit
set -o pipefail

export GCP_PROJECT_ID="greg-apigee-hybrid-eks"
export CLOUDSDK_CORE_DISABLE_PROMPTS="1"
export SHORT_SHA="$(git rev-parse --short HEAD)"
#export GCP_SA_JSON=$(find ./config/creds/*.json)

environment() {
    echo "Setting up environment..."
    yq  '.substitutions._SHORT_SHA |= env(SHORT_SHA) | .substitutions._SHORT_SHA style="double"' -i ./image/cloudbuild.yaml
    PROJECT_ID=$(yq '.environment.project_id' settings.yaml)         yq '.substitutions._PROJECT_ID        |= env(PROJECT_ID)        | .substitutions._PROJECT_ID style="double"'        -i ./image/cloudbuild.yaml
    PROJECT_ID=$(yq '.environment.project_id' settings.yaml)         yq '.substitutions._PROJECT_ID        |= env(PROJECT_ID)        | .substitutions._PROJECT_ID style="double"'        -i ./config/cloudbuild.yaml    
    TEST_NAME=$(yq '.environment.test_name' settings.yaml)           yq '.substitutions._TEST_NAME         |= env(TEST_NAME)         | .substitutions._TEST_NAME style="double"'         -i ./config/cloudbuild.yaml
    LOCATION=$(yq '.environment.location' settings.yaml)             yq '.substitutions._LOCATION          |= env(LOCATION)          | .substitutions._LOCATION style="double"'          -i ./config/cloudbuild.yaml
    K6_DURATION=$(yq '.k6.duration' settings.yaml)                   yq '.substitutions._K6_DURATION       |= env(K6_DURATION)       | .substitutions._K6_DURATION style="double"'       -i ./config/cloudbuild.yaml
    K6_VUS=$(yq '.k6.vus' settings.yaml)                             yq '.substitutions._K6_VUS            |= env(K6_VUS)            | .substitutions._K6_VUS style="double"'            -i ./config/cloudbuild.yaml
    BQ_DATASET_NAME=$(yq '.bigquery.dataset_name' settings.yaml)     yq '.substitutions._BQ_DATASET_NAME   |= env(BQ_DATASET_NAME)   | .substitutions._BQ_DATASET_NAME style="double"'   -i ./config/cloudbuild.yaml
    BQ_DATASET_FORMAT=$(yq '.bigquery.dataset_format' settings.yaml) yq '.substitutions._BQ_DATASET_FORMAT |= env(BQ_DATASET_FORMAT) | .substitutions._BQ_DATASET_FORMAT style="double"' -i ./config/cloudbuild.yaml
    BQ_DATASET_DESC=$(yq '.bigquery.dataset_desc' settings.yaml)     yq '.substitutions._BQ_DATASET_DESC   |= env(BQ_DATASET_DESC)   | .substitutions._BQ_DATASET_DESC style="double"'   -i ./config/cloudbuild.yaml
    BQ_TABLE_NAME=$(yq '.bigquery.table_name' settings.yaml)         yq '.substitutions._BQ_TABLE_NAME     |= env(BQ_TABLE_NAME)     | .substitutions._BQ_TABLE_NAME style="double"'     -i ./config/cloudbuild.yaml
    GCS_BUCKET_NAME=$(yq '.gcs.bucket_name' settings.yaml)           yq '.substitutions._GCS_BUCKET_NAME   |= env(GCS_BUCKET_NAME)   | .substitutions._GCS_BUCKET_NAME style="double"'   -i ./config/cloudbuild.yaml
    GCS_FILE_NAME=$(yq '.gcs.file_name' settings.yaml)                yq '.substitutions._GCS_FILE_NAME     |= env(GCS_FILE_NAME)     | .substitutions._GCS_FILE_NAME style="double"'     -i ./config/cloudbuild.yaml
}


build(){
    environment
    gcloud config set project ${GCP_PROJECT_ID}
   #sudo apt-get install google-cloud-sdk-cloud-build-local
    #gcloud components install cloud-build-local -q
    #gcloud components update cloud-build-local -q

    gcloud builds submit --config ./image/cloudbuild.yaml
}

local(){
    environment
    export TEST_PATH="./config"
    rm -rf $TEST_PATH/workspace

    cloud-build-local \
      --config=${TEST_PATH}/cloudbuild.yaml \
      --write-workspace=$TEST_PATH \
      --dryrun=false $TEST_PATH
}

cloud(){
    environment
    export TEST_PATH="./config"
    rm -rf $TEST_PATH/workspace

    gcloud builds submit ${TEST_PATH} \
      --config=${TEST_PATH}/cloudbuild.yaml
}

run() {
    logo=$(tput setaf 6)
    warn=$(tput setaf 3)
    bold=$(tput bold)
    normal=$(tput sgr0)
    
    SHORT_SHA="$(git rev-parse --short HEAD)"
    BRANCH="$(git branch --show-current)"
    LOGO="$(wget -q -O /tmp/logo artii.herokuapp.com/make?text=k6x&font=small)"
    LOGO="$(cat /tmp/logo)"
    
    rm -rf /tmp/logo

    MULTIPLIER=$(yq '.k6.multiplier' settings.yaml) && MULTIPLIER=$(echo "$(($MULTIPLIER-1))")
    DURATION=$(yq '.k6.duration' settings.yaml)
    VUS=$(yq '.k6.vus' settings.yaml)

    echo "${logo}${LOGO}${normal}"
    echo "${logo}Version: ${BRANCH}-${SHORT_SHA}${normal}"
    echo "${logo}Multiplier: ${MULTIPLIER}${normal}"
    echo "${logo}Duration: ${DURATION}${normal}"
    echo "${logo}VUS (Virtual Users): ${VUS}${normal}"

    for (( i = 0; i <= $MULTIPLIER; i++ )); do                                            
        cloud $i &                                                                    
    done
    wait
}

"$@"

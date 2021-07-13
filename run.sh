#!/bin/bash
set -o errexit
set -o pipefail

environment() {
  source settings
  echo "Setting up environment..."
  yq eval '.substitutions._TEST_NAME              |= ''"'$TEST_NAME'"'              -i ./config/cloudbuild_local.yaml
  yq eval '.substitutions._IMG_DEST               |= ''"'$IMG_DEST'"'               -i ./config/cloudbuild_local.yaml
  yq eval '.substitutions._LOCATION               |= ''"'$LOCATION'"'               -i ./config/cloudbuild_local.yaml
  yq eval '.substitutions._K6_VUS                 |= ''"'$K6_VUS'"'                 -i ./config/cloudbuild_local.yaml
  yq eval '.substitutions._K6_DURATION            |= ''"'$K6_DURATION'"'            -i ./config/cloudbuild_local.yaml
  yq eval '.substitutions._BQ_DATASET_NAME        |= ''"'$BQ_DATASET_NAME'"'        -i ./config/cloudbuild_local.yaml
  yq eval '.substitutions._BQ_DATASET_FORMAT      |= ''"'$BQ_DATASET_FORMAT'"'      -i ./config/cloudbuild_local.yaml
  yq eval '.substitutions._BQ_DATASET_DESCRIPTION |= ''"'$BQ_DATASET_DESCRIPTION'"' -i ./config/cloudbuild_local.yaml
  yq eval '.substitutions._BQ_TABLE_NAME          |= ''"'$BQ_TABLE_NAME'"'          -i ./config/cloudbuild_local.yaml
  yq eval '.substitutions._GCS_FILE_NAME          |= ''"'$GCS_FILE_NAME'"'          -i ./config/cloudbuild_local.yaml
  yq eval '.substitutions._GCS_BUCKET_NAME        |= ''"'$GCS_BUCKET_NAME'"'        -i ./config/cloudbuild_local.yaml
  yq eval '.substitutions._GCP_SA_EMAIL           |= ''"'$GCP_SA_EMAIL'"'           -i ./config/cloudbuild_local.yaml
}

ddos-local(){
    environment
    export TEST_PATH="./config"
    rm -rf $TEST_PATH/workspace

    cloud-build-local \
      --config=${TEST_PATH}/cloudbuild_local.yaml \
      --write-workspace=$TEST_PATH \
      --dryrun=false $TEST_PATH
}

ddos-cloud(){
    environment
    export TEST_PATH="./config"
    rm -rf $TEST_PATH/workspace

    gcloud builds submit ${TEST_PATH} \
      --config=${TEST_PATH}/cloudbuild.yaml
}

"$@"
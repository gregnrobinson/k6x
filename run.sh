#!/bin/bash
set -o errexit
set -o pipefail

environment() {
  echo "Setting up environment..."
  TEST_NAME=$(yq e '.environment.test_name' settings.yaml)           yq e '.substitutions._TEST_NAME         |= env(TEST_NAME)         | .substitutions._TEST_NAME style="double"'         -i ./config/cloudbuild.yaml
  IMG_DEST=$(yq e '.environment.img_dest' settings.yaml)             yq e '.substitutions._IMG_DEST          |= env(IMG_DEST)          | .substitutions._IMG_DEST style="double"'          -i ./config/cloudbuild.yaml
  LOCATION=$(yq e '.environment.location' settings.yaml)             yq e '.substitutions._LOCATION          |= env(LOCATION)          | .substitutions._LOCATION style="double"'          -i ./config/cloudbuild.yaml
  K6_DURATION=$(yq e '.k6.duration' settings.yaml)                   yq e '.substitutions._K6_DURATION       |= env(K6_DURATION)       | .substitutions._K6_DURATION style="double"'       -i ./config/cloudbuild.yaml
  K6_VUS=$(yq e '.k6.vus' settings.yaml)                             yq e '.substitutions._K6_VUS            |= env(K6_VUS)            | .substitutions._K6_VUS style="double"'            -i ./config/cloudbuild.yaml
  BQ_DATASET_NAME=$(yq e '.bigquery.dataset_name' settings.yaml)     yq e '.substitutions._BQ_DATASET_NAME   |= env(BQ_DATASET_NAME)   | .substitutions._BQ_DATASET_NAME style="double"'   -i ./config/cloudbuild.yaml
  BQ_DATASET_FORMAT=$(yq e '.bigquery.dataset_format' settings.yaml) yq e '.substitutions._BQ_DATASET_FORMAT |= env(BQ_DATASET_FORMAT) | .substitutions._BQ_DATASET_FORMAT style="double"' -i ./config/cloudbuild.yaml
  BQ_DATASET_DESC=$(yq e '.bigquery.dataset_desc' settings.yaml)     yq e '.substitutions._BQ_DATASET_DESC   |= env(BQ_DATASET_DESC)   | .substitutions._BQ_DATASET_DESC style="double"'   -i ./config/cloudbuild.yaml
  BQ_TABLE_NAME=$(yq e '.bigquery.table_name' settings.yaml)         yq e '.substitutions._BQ_TABLE_NAME     |= env(BQ_TABLE_NAME)     | .substitutions._BQ_TABLE_NAME style="double"'     -i ./config/cloudbuild.yaml
  GCS_BUCKET_NAME=$(yq e '.gcs.bucket_name' settings.yaml)           yq e '.substitutions._GCS_BUCKET_NAME   |= env(GCS_BUCKET_NAME)   | .substitutions._GCS_BUCKET_NAME style="double"'   -i ./config/cloudbuild.yaml
  GCS_FILE_NAME=$(yq e '.gcs.file_name' settings.yaml)               yq e '.substitutions._GCS_FILE_NAME     |= env(GCS_FILE_NAME)     | .substitutions._GCS_FILE_NAME style="double"'     -i ./config/cloudbuild.yaml
}

ddos-local(){
    environment
    export TEST_PATH="./config"
    rm -rf $TEST_PATH/workspace

    cloud-build-local \
      --config=${TEST_PATH}/cloudbuild.yaml \
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
# Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
  * [Create a Service Account](#create-a-service-account)
  * [Edit `./settings.yaml`](#edit-settingsyaml)
  * [Edit `./config/urls`](#edit-configurls)
- [Build the K6x image](#build-the-k6x-image)
- [Run a k6x load test](#run-a-k6x-load-test)
- [GitOps & CloudBuild](#gitops--cloudbuild)
  * [Link a repository with this source code](#link-a-repository-with-this-source-code)
  * [Run the pipeline.](#run-the-pipeline)
  * [Setup Pipeline Schedule](#setup-pipeline-schedule)
- [Reference](#reference)

# Overview

Ths project is used to Extract, Transform, and Load network data into BigQuery using CloudBuild Pipelines and [NDJSON Datasets](http://ndjson.org/). The pipeline will first extract the data using an opensource package by [K6](https://k6.io/). After K6 collects the data, jq is invoked to clean the output so the dataset can be loaded into BigQuery for analysis. During every run a new JSON dataset is appended to the dataset BigQuery. The datasets are also archived to GCS and time stamped accordingly.

# Prerequisites

To operate with this repository, make sure you have the following packages installed.

- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- [Docker Engine](https://https://docs.docker.com/engine/install/)
- [yq](https://mikefarah.gitbook.io/yq/) *Used for updating the Cloudbuild settings from the settings.yaml file*

## Create a Service Account

Create and copy your GCP Service Account JSON Key file within the `./config/creds/` directory. K6x will detect it automatically find it and inject it into the container at runtime. No credentials are permenantly stored within the k6x image. All `.json` files are ignored by Git by default.

Either assign the `Editor` role to the Service Account or use only the required roles to satisfy the requirements for k6.

## Edit `settings.yaml`

Example settings.json

```yaml
environment:
  name: "perfmon_test"
  location: "northamerica-northeast1"
  img_dest: "gcr.io/gregnrobinson/k6x"

k6:
  duration: "30s"
  multiplier: "1" # Define how many synchronous k6 runs should execute
  vus: "1"

bigquery:
  dataset_name: "perftest_dataset"
  dataset_format: "NEWLINE_DELIMITED_JSON"
  table_name: "perftest_table"
  dataset_desc: "perftest"

gcs:
  bucket_name: "perfmon_test"
  file_name: "metrics.json"
```

## Edit `./config/urls`

Define the list of URLs that K6 should test against. Enter one URL per line.

Example:
```
https://google.ca
https://facebook.com
...
```

# Build the K6x image

*Use the provided `image/cloudbuild_local.yaml` file to build the docker image locally, or use the `image/cloudbuild.yaml` to build the image within Google Cloud Build. the deliniation is that building an image locally uses your own computer and Docker Engine to perform the operations. Building in Google Cloud Build will perform the operations on a GCP VM that is dynamically created at runtime so you delegate the oerations comletely to Google Cloud Build. This is useful for creating a Cloud Build pipeline trigger to run at a desired frequency to update dashboards that read from a Big Query dataset.*

The Dockerfile used to build the k6x image was sourced from [Google Cloud SDK Dockerfile](https://github.com/GoogleCloudPlatform/cloud-sdk-docker/blob/master/Dockerfile) with the additional components including K6 and other dependancy requirements for handling data.

The Dockerfile is located at `./image/Dockerfile`.

To build and push the k6x image to GCR, run the following command:

```shell
./k6x.sh build
```
# Run a k6x load test

To run a k6x load test, run the following command:

```shell
./k6x.sh run
```

The `k6:` section in `settings.yaml` has the following settings to dictate how k6 should execute the load test.`

```yaml
k6:
  duration: "30s" # how long should k6 run for
  multiplier: "1" # Define how many synchronous k6 runs should execute
  vus: "1" # how many synchronous virtual users should be executing the load tests
```

With the addition of the multiplier, you can run up to 10 synchronous k6 runs times the number of virtual users per run. Because k6x runs on Google Cloud Build, you don't have to worry about resource limits on your local machine.

# GitOps & CloudBuild

## Link a repository with this source code

Go to the GCP ***console > Cloud Build > Triggers*** to connect your repository and add the trigger details matching the desired expression. The default configuration is a push or merge to the main branch which will trigger the pipeline.

## Run the pipeline.

Trigger the pipeline by matching your trigger condition and thats it. 

## Setup Pipeline Schedule

Setup a CRON schedule to automatically add a new dataset to BigQuery when it becomes available.

In order to set the schedule it is requried to use the app engine default service account `0@appspot.gserviceaccount.com`. If you have never used app engine, enable the API using the following command:

```sh
gcloud services enable appengine.googleapis.com --project ${PROJECT_ID}
```

Add the following permissions to `0@appspot.gserviceaccount.com`

- Cloud Build Service Account
- Cloud Scheduler Service Agent

Create a CloudBuild schedule by setting the trigger to `manual invocation` and then the option for setting a schedule will appear. 

Now the cloudbuild data pipelines will update the dataset without any internvention. This is useful for keeping graphs and charts that use BigQuery up to date wthout any manual intervention.
|
# Reference
- https://cloud.google.com/bigquery/docs/datasets#bq
- https://cloud.google.com/iam/docs/understanding-roles-
- https://cloud.google.com/bigquery/docs/reference/bq-cli-reference
- https://cloud.google.com/storage/docs/gsutil/commands/cp
- https://cloud.google.com/scheduler/docs
- https://github.com/GoogleCloudPlatform/cloud-sdk-docker/blob/master/Dockerfile

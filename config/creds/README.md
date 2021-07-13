# Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Build the K6 image](#build-the-k6-image)
- [Test Data Pipelines](#test-data-pipelines)
- [GitOps & CloudBuild](#gitops---cloudbuild)
  * [Link a repository containing the `./cloudbuild.yaml` file.](#link-a-repository-containing-the---cloudbuildyaml--file)
  * [Run the pipeline.](#run-the-pipeline)
  * [Setup Pipeline Schedule](#setup-pipeline-schedule)
- [Reference](#reference)

# Overview

**Current Dashboard Link:** https://arctiq-data-lab.nn.r.appspot.com/superset/dashboard/telus_dashboard/

![telus_web_architecture](https://user-images.githubusercontent.com/26353407/120719392-3056cc80-c498-11eb-8b8b-8a0c6c3a6026.png)

Ths project is used to Extract, Transform, and Load network data into BigQuery using CloudBuild Pipelines and [NDJSON Datasets](http://ndjson.org/). The pipeline will first extract the data using an opensource package by [K6](https://k6.io/). After K6 collects the data, jq is invoked to clean the output so the dataset can be loaded into BigQuery for analysis. During every run a new JSON dataset is appended to the dataset BigQuery. The datasets are also archived to GCS and time stamped accordingly.

# Prerequisites

To operate with this repository, make sure you have the following packages installed.

- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- [Docker Engine](https://https://docs.docker.com/engine/install/)
- [Python](https://www.python.org/downloads/) *For the helper tool to generate K6 templates and extract URLs*

# Build the K6 image

Use the provided `image/cloudbuild.yaml` and `image/Dockerfile` to perform a build task on the image the same way the pipeline would. This is useful for debugging.

This Dockerfile nuilt upon the official [Google Cloiud SDK Dockerfile](https://github.com/GoogleCloudPlatform/cloud-sdk-docker/blob/master/Dockerfile) with the additional components including ethr and K6 for metric collection.

To build and push without a prompt for your project id, create an environment variable named `PROJECT_ID`:
```shell
export PROJECT_ID="<YOUR_PROJECT_ID>"
```

To build and push run the following command:

```shell
./build.sh
```
# Test Data Pipelines

After the base image is built and pushed to gcr, the data pipelines can be run using the test script which run the data collection and export to a seperate bigquery table that the dashboards are linked to. Each test is function in the test.sh file and can executed by passing the test name after `./test.sh`. For example:
```
./test.sh cidc
```
# GitOps & CloudBuild

## Link a repository containing the `./cloudbuild.yaml` file.

Go to the GCP ***console > Cloud Build > Triggers*** to connect your repository and add the trigger details matching the desired expression. The default configuration is a push or merge to the main branch which will trigger the pipeline.

## Run the pipeline.

Trigger the pipeline by matching your trigger condition and thats it. 

## Setup Pipeline Schedule

Setup a CRON schedule to automatically add a new dataset to BigQuery when it becomes available.

To make life easier, set your project ID in the terminall using the following command.

```sh
export PROJECT_ID="<your_project_id>"
```

In order to set the schedule it is requried to use the app engine default service account `0@appspot.gserviceaccount.com`. If you have never used app engine, enable the API using the following command:

```sh
gcloud services enable appengine.googleapis.com --project ${PROJECT_ID}
```

Add the following permissions to `0@appspot.gserviceaccount.com`

- Cloud Build Service Account
- Cloud Scheduler Service Agent

Create a CloudBuild schedule by setting the trigger to `manual invocation` and then the option for setting a schedule will appear. 

Now the cloudbuild data pipelines will update the dataset without any internvention. This is useful for keeping graphs and charts that use BigQuery up to date wthout any manual intervention.                                       |
# Reference

- https://cloud.google.com/bigquery/docs/datasets#bq
- https://cloud.google.com/iam/docs/understanding-roles-
- https://cloud.google.com/bigquery/docs/reference/bq-cli-reference
- https://cloud.google.com/storage/docs/gsutil/commands/cp
- https://cloud.google.com/scheduler/docs
- https://github.com/GoogleCloudPlatform/cloud-sdk-docker/blob/master/Dockerfile

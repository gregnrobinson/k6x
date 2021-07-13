FROM docker:19.03.11 AS static-docker-source
FROM loadimpact/k6:latest AS k6official
FROM debian:buster-slim

ARG CLOUD_SDK_VERSION=348.0.0
ENV CLOUD_SDK_VERSION=$CLOUD_SDK_VERSION
ENV PATH "$PATH:/opt/google-cloud-sdk/bin/"

COPY --from=static-docker-source /usr/local/bin/docker /usr/local/bin/docker
COPY --from=k6official /usr/bin/k6 /usr/bin/k6

RUN groupadd -r -g 1000 cloudsdk && \
    useradd -r -u 1000 -m -s /bin/bash -g cloudsdk cloudsdk

ARG INSTALL_COMPONENTS
RUN mkdir -p /usr/share/man/man1/
RUN apt-get update -qqy && apt-get install -qqy \
        curl \
        gcc \
        python3-dev \
        python3-pip \
        apt-transport-https \
        lsb-release \
        openssh-client \
        git \
        wget \
        unzip \
        snapd \
        gnupg2 \
        ca-certificates \
        jq \
        moreutils \
        ntp \
        gnupg && \
    pip3 install -U crcmod && \
    export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
    echo "deb https://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" > /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    apt-get update && apt-get install -y google-cloud-sdk=${CLOUD_SDK_VERSION}-0 $INSTALL_COMPONENTS && \
    gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true && \
    gcloud config set metrics/environment github_docker_image && \
    gcloud --version

RUN wget https://github.com/mikefarah/yq/releases/download/v4.9.3/yq_linux_amd64 -O /usr/bin/yq && \
    chmod +x /usr/bin/yq

RUN wget https://github.com/microsoft/ethr/releases/latest/download/ethr_linux.zip && \
    unzip ethr_linux.zip && \
    mv ethr /usr/local/bin && \
    rm ethr_linux.zip

RUN git config --system credential.'https://source.developers.google.com'.helper gcloud.sh

RUN apt-get update && apt-get upgrade -y
ENV TZ America/Toronto
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

VOLUME ["/root/.config"]



FROM docker:17.12.0-ce as static-docker-source

FROM python:3.6-stretch
ARG CLOUD_SDK_VERSION=297.0.1
ENV CLOUD_SDK_VERSION=$CLOUD_SDK_VERSION

COPY --from=static-docker-source /usr/local/bin/docker /usr/local/bin/docker
RUN apt-get -qqy update && apt-get install -qqy \
        curl \
        gcc \
        apt-transport-https \
        lsb-release \
        openssh-client \
        git \
        gnupg \
    && pip install -U crcmod   && \
    export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
    echo "deb https://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" > /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    apt-get update && \
    apt-get install -y google-cloud-sdk=${CLOUD_SDK_VERSION}-0 kubectl && \
    gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true && \
    gcloud config set metrics/environment github_docker_image && \
    gcloud --version && \
    docker --version && kubectl version --client

RUN apt-get install default-libmysqlclient-dev -qqy
ENV AIRFLOW_GPL_UNIDECODE="yes"
#ENV SLUGIFY_USES_TEXT_UNIDECODE="yes"
# Default requirements
ADD requirements.txt /tmp/requirements.txt
RUN pip3 install -r /tmp/requirements.txt
# Extra requirements
ADD requirements.extra.txt /tmp/requirements.extra.txt
RUN pip3 install -r /tmp/requirements.extra.txt
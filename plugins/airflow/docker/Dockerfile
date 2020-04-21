# Trying to follow versions given by Google Cloud Composer
# https://cloud.google.com/composer/docs/concepts/python-version?hl=nb
ARG IMAGE=set-this
FROM ${IMAGE}

RUN apt-get update
RUN apt-get install openjdk-8-jre -y
# Install gcloud
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
| tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
| apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - && apt-get update -y && apt-get install google-cloud-sdk -y


RUN pip install --upgrade pip
ENV AIRFLOW_GPL_UNIDECODE="yes"
ARG AIRFLOW_VERSION=set-this
ADD requirements.${AIRFLOW_VERSION}.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

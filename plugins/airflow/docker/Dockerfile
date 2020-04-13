# Trying to follow versions given by Google Cloud Composer
# https://cloud.google.com/composer/docs/concepts/python-version?hl=nb
ARG IMAGE=set-this
FROM ${IMAGE}

RUN apt-get update
RUN apt-get install openjdk-8-jre -y

ENV AIRFLOW_GPL_UNIDECODE="yes"
ARG AIRFLOW_VERSION=set-this
ARG AIRFLOW_EXTRAS=gcp,postgres
RUN pip install apache-airflow[${AIRFLOW_EXTRAS}]==${AIRFLOW_VERSION}

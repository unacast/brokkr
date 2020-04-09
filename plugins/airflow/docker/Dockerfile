ARG IMAGE=python:3.7-stretch
FROM ${IMAGE}

RUN apt-get update
RUN apt-get install openjdk-8-jre -y

ENV AIRFLOW_GPL_UNIDECODE="yes"
ARG AIRFLOW_VERSION=1.10.6
ARG AIRFLOW_EXTRAS=gcp,postgres
RUN pip install apache-airflow[${AIRFLOW_EXTRAS}]==${AIRFLOW_VERSION}

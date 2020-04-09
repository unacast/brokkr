.SILENT: ;
.DEFAULT_GOAL :=  help
include ../../help/help.mk

# We default to 1.10.6, which is the highest version supported
# by Google Cloud Composer at the moment
ifndef AIRFLOW_VERSION
AIRFLOW_VERSION := 1.10.6
endif

ifndef AIRFLOW_EXTRAS
AIRFLOW_EXTRAS := gcp,postgres
endif

build: ## Builds the docker image given AIRFLOW_VERSION and AIRFLOW_EXTRAS
	docker build --build-arg IMAGE=python:3.7-stretch \
		--build-arg AIRFLOW_VERSION=$(AIRFLOW_VERSION) \
		--build-arg AIRFLOW_EXTRAS=$(AIRFLOW_EXTRAS) \
		-t unacast/airflow:$(AIRFLOW_VERSION) .

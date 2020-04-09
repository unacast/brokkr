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

.PHONY: build
build: ## Builds the docker image given AIRFLOW_VERSION and AIRFLOW_EXTRAS
	docker build --build-arg IMAGE=python:3.7-stretch \
		--build-arg AIRFLOW_VERSION=$(AIRFLOW_VERSION) \
		--build-arg AIRFLOW_EXTRAS=$(AIRFLOW_EXTRAS) \
		-t unacast/airflow:$(AIRFLOW_VERSION) .
.PHONY: push
push: ## Push to dockerhub given AIRFLOW_TAG
	$(if $(value AIRFLOW_TAG),, $(error AIRFLOW_TAG environment variable is not set.))
	docker push unacast/airflow:$(AIRFLOW_TAG)

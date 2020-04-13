.SILENT: ;
.DEFAULT_GOAL :=  help
include ../../help/help.mk

AIRFLOW_EXTRAS_POST_1_10_3=gcp,postgres,sendgrid,kubernetes,aws,slack
AIRFLOW_EXTRAS_PRE_1_10_6=gcp_api,postgres,sendgrid,kubernetes,s3,slack
ifndef IMAGE
IMAGE := python:3.6.8-stretch
endif

.PHONY: build
build: ## Builds the docker image given AIRFLOW_VERSION and AIRFLOW_EXTRAS
	$(if $(value AIRFLOW_VERSION),, $(error AIRFLOW_VERSION environment variable is not set.))
	$(if $(value AIRFLOW_EXTRAS),, $(error AIRFLOW_EXTRAS environment variable is not set.))

	docker build --build-arg IMAGE=$(IMAGE) \
		--build-arg AIRFLOW_VERSION=$(AIRFLOW_VERSION) \
		--build-arg AIRFLOW_EXTRAS=$(AIRFLOW_EXTRAS) \
		-t unacast/airflow:$(AIRFLOW_VERSION) .

.PHONY: build.all
build.all: ## Build all the docker images
	$(MAKE) airflow-1.10.2
	$(MAKE) airflow-1.10.3
	$(MAKE) airflow-1.10.6
	$(MAKE) airflow-1.10.9
	$(MAKE) airflow-1.10.10

.PHONY: airflow-1.10.2
airflow-1.10.2: ## Build docker image 1.10.2
	AIRFLOW_VERSION=1.10.2 AIRFLOW_EXTRAS=$(AIRFLOW_EXTRAS_PRE_1_10_6) $(MAKE) build

.PHONY: airflow-1.10.3
airflow-1.10.3: ## Build docker image 1.10.2
	AIRFLOW_VERSION=1.10.3 AIRFLOW_EXTRAS=$(AIRFLOW_EXTRAS_PRE_1_10_6) $(MAKE) build

.PHONY: airflow-1.10.6
airflow-1.10.6: ## Build docker image 1.10.6
	AIRFLOW_VERSION=1.10.6 AIRFLOW_EXTRAS=$(AIRFLOW_EXTRAS_POST_1_10_3) $(MAKE) build

.PHONY: airflow-1.10.9
airflow-1.10.9: ## Build docker image 1.10.9
	AIRFLOW_VERSION=1.10.9 AIRFLOW_EXTRAS=$(AIRFLOW_EXTRAS_POST_1_10_3) $(MAKE) build

.PHONY: airflow-1.10.10
airflow-1.10.10: ## Build docker image 1.10.10
	AIRFLOW_VERSION=1.10.10 AIRFLOW_EXTRAS=$(AIRFLOW_EXTRAS_POST_1_10_3) $(MAKE) build

.PHONY: push
push: ## Push to dockerhub given AIRFLOW_TAG
	$(if $(value AIRFLOW_TAG),, $(error AIRFLOW_TAG environment variable is not set.))
	docker push unacast/airflow:$(AIRFLOW_TAG)

.PHONY: push.all
push.all: ## Pushes all images to dockerhub
	docker push unacast/airflow:1.10.2
	docker push unacast/airflow:1.10.3
	docker push unacast/airflow:1.10.6
	docker push unacast/airflow:1.10.9
	docker push unacast/airflow:1.10.10
.EXPORT_ALL_VARIABLES:
AIRFLOW_WORKFOLDER=.airflow
AIRFLOW_DOCKER_COMPOSE_FILE=$(AIRFLOW_WORKFOLDER)/docker-compose.yml
AIRFLOW_DOCKER_ENVIRONMENT_VARS=$(AIRFLOW_WORKFOLDER)/docker-environment-variables.properties
AIRFLOW_SENTINELS_FOLDER=$(AIRFLOW_WORKFOLDER)/sentinels
COMPOSE_PROJECT_NAME=$(notdir $(CURDIR))

ifndef AIRFLOW_DOCKER_IMAGE
AIRFLOW_DOCKER_IMAGE := python:3.6.6
endif

ifndef AIRFLOW_VIRTUAL_ENV_FOLDER
AIRFLOW_VIRTUAL_ENV_FOLDER := .venv
endif

ifndef AIRFLOW_WEBSERVER_PORT
AIRFLOW_WEBSERVER_PORT := 8080
endif

ifndef AIRFLOW_VARIABLES
AIRFLOW_VARIABLES := airflow-variables.json
endif

ifndef AIRFLOW_DAGS_FOLDER
AIRFLOW_DAGS_FOLDER :=dags
endif

ifndef AIRFLOW_REQUIREMENTS_TXT
AIRFLOW_REQUIREMENTS_TXT := requirements.txt
endif

.PHONY: start.airflow
start.airflow: $(AIRFLOW_SENTINELS_FOLDER)/db-init.sentinel ## Start Airflow server
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) up -d db
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) up -d webserver
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) up -d scheduler

.PHONY: stop.airflow
stop.airflow: $(AIRFLOW_WORKFOLDER)/docker-compose.yml ## Stop running Airflow server
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) stop

.PHONY: logs.airflow
logs.airflow: $(AIRFLOW_WORKFOLDER)/docker-compose.yml ## Tail the local logs
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) logs --follow

.PHONY: test.airflow
test.airflow: $(AIRFLOW_SENTINELS_FOLDER)/requirements.sentinel ## Run the tests found in /test
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run --rm -e PYTHONPATH=$(AIRFLOW_DAGS_FOLDER):test test pytest

.PHONY: flake8.airflow
flake8.airflow: $(AIRFLOW_SENTINELS_FOLDER)/requirements.sentinel ## Run the flake8 agains dags folder
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run --rm test flake8 $(AIRFLOW_DAGS_FOLDER)
	@echo Flake 8 OK!s

.PHONY: clean.airflow
clean.airflow: ## Removes .airflow folder and docker containers
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) down
	rm -rf $(AIRFLOW_WORKFOLDER)

.PHONY: list.airflow
error.airflow: ## List all dags, and filter errors
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run webserver airflow list_dags | grep -B5000 "DAGS"

.PHONY: venv.airflow
venv.airflow: ## Create a virtual environment folder for Code-completion and tests inside your IDE
	virtualenv -p python3 $(AIRFLOW_VIRTUAL_ENV_FOLDER); \
	source $(AIRFLOW_VIRTUAL_ENV_FOLDER)/bin/activate; \
	export AIRFLOW_GPL_UNIDECODE="yes"; \
	pip install -r requirements.txt;


#####################################################################
# These are the docker files that we use during local runs of Airflow
# docker-compose.yml consists of a PostgreSQL backend, Airflow 
# webserver, Airflow scheduler and a container for flake8 and pytest 
# runs
####################################################################
define AIRFLOW_DOCKER_COMPOSE
version: '3.7'
services:
  db:
    image: postgres:9.6
    environment:
    - POSTGRES_USER=airflow
    - POSTGRES_PASSWORD=airflow
    - POSTGRES_DB=airflow

  webserver:
    depends_on:
      - db          
    build:
      context: $${PWD}
      dockerfile: $(AIRFLOW_WORKFOLDER)/Dockerfile
    working_dir: /code
    env_file: $${PWD}/$(AIRFLOW_DOCKER_ENVIRONMENT_VARS)
    ports:
      - "$(AIRFLOW_WEBSERVER_PORT):8080"
    volumes:
      - "$${PWD}/:/code"
      - logs-volume:/root/airflow/logs/
    command: airflow webserver

  scheduler:
    depends_on:
      - db          
    build:
      context: $${PWD}
      dockerfile: $(AIRFLOW_WORKFOLDER)/Dockerfile
    working_dir: /code
    env_file: $${PWD}/$(AIRFLOW_DOCKER_ENVIRONMENT_VARS)
    volumes:
      - "$${PWD}/:/code"
      - logs-volume:/root/airflow/logs/
    command: airflow scheduler

  test:
    build:
      context: $${PWD}
      dockerfile: $(AIRFLOW_WORKFOLDER)/Dockerfile
    working_dir: /code
    volumes:
      - "$${PWD}/:/code"

volumes:
  logs-volume:
endef
export AIRFLOW_DOCKER_COMPOSE

define AIRFLOW_DOCKERFILE
FROM $(AIRFLOW_DOCKER_IMAGE)

RUN apt-get update
RUN apt-get install openjdk-8-jre -y

ADD $(AIRFLOW_REQUIREMENTS_TXT) /tmp/requirements.txt
ENV AIRFLOW_GPL_UNIDECODE="yes"
RUN pip install -r /tmp/requirements.txt
endef
export AIRFLOW_DOCKERFILE

############################################################
# These are various pre-steps that are needed before running
# the webserver, flake8 or tests
############################################################

# Create the working folder
$(AIRFLOW_WORKFOLDER):
	mkdir -p $(AIRFLOW_WORKFOLDER)

# Create a sentinels folder. Sentinel files are empty files
# used to make sure targets have run and skip them.
# Other targets depends on these sentinel files
$(AIRFLOW_SENTINELS_FOLDER): | $(AIRFLOW_WORKFOLDER)
	mkdir -p $(AIRFLOW_WORKFOLDER)/sentinels

# This creates the docker-compose.yml file.
$(AIRFLOW_WORKFOLDER)/docker-compose.yml: | $(AIRFLOW_WORKFOLDER)
	echo "$$AIRFLOW_DOCKERFILE" > $(AIRFLOW_WORKFOLDER)/Dockerfile
	echo "$$AIRFLOW_DOCKER_COMPOSE" > $(AIRFLOW_WORKFOLDER)/docker-compose.yml

# Ensure that we have started the PostgreSQL and ran airflow initdb
$(AIRFLOW_SENTINELS_FOLDER)/db-init.sentinel: $(AIRFLOW_SENTINELS_FOLDER)/requirements.sentinel
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) up -d db
	# Wait for postgreSQL to start
	sleep 5
	# TODO: This does create not needed errors because variables are needed
	# Could perhaps try to manipulate the DAGS_FOLDER
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run --rm webserver airflow initdb
	if [ -f "$(AIRFLOW_VARIABLES)" ]; then \
	 	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run --rm webserver airflow variables -i /code/$(AIRFLOW_VARIABLES); \
	fi
	touch $@

# Ensure that python requirements have run.
# Will rerun on changes on requirements.txt
$(AIRFLOW_SENTINELS_FOLDER)/requirements.sentinel: $(AIRFLOW_REQUIREMENTS_TXT) $(AIRFLOW_WORKFOLDER)/docker-compose.yml \
$(AIRFLOW_DOCKER_ENVIRONMENT_VARS) | $(AIRFLOW_SENTINELS_FOLDER)
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) build
	touch $@

# Docker environment file
# Various AIRFLOW settings and url to database
$(AIRFLOW_DOCKER_ENVIRONMENT_VARS): | $(AIRFLOW_WORKFOLDER)
	echo AIRFLOW__CORE__EXECUTOR=LocalExecutor > $@
	echo AIRFLOW__CORE__SQL_ALCHEMY_CONN=postgresql+psycopg2://airflow:airflow@db:5432/airflow >> $@
	echo AIRFLOW__CELERY__RESULT_BACKEND=db+postgresql://airflow:airflow@db:5432/airflow >> $@
	echo AIRFLOW__CORE__DAGS_FOLDER=$(AIRFLOW_DAGS_FOLDER) >> $@
	echo AIRFLOW__CORE__LOAD_EXAMPLES=False >> $@
	if [ -f "airflow-env-vars.properties" ]; then \
		cat ${PWD}/airflow-env-vars.properties >> $@; \
	fi

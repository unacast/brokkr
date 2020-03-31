.EXPORT_ALL_VARIABLES:
AIRFLOW_DOCKER_COMPOSE_FILE=.airflow/docker-compose.yml
AIRFLOW_DOCKER_ENVIRONMENT_VARS=.airflow/docker-environment-variables.properties
COMPOSE_PROJECT_NAME=$(notdir $(CURDIR))
ifndef AIRFLOW_REQUIREMENTS_TXT
AIRFLOW_REQUIREMENTS_TXT := requirements.txt
endif

.PHONY: start
start: .airflow/sentinels/db-init.sentinel ## Start Airflow server
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) up -d db
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) up -d airflow
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) up -d scheduler

.PHONY: stop
stop: .airflow/sentinels/requirements.sentinel ## Stop running Airflow server
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) stop

.PHONY: logs
logs: ## Tail the local logs
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) logs --follow

.PHONY: test
test: .airflow/sentinels/requirements.sentinel ## Run the tests found in /test
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run --rm -e PYTHONPATH=dags:test test pytest

.PHONY: flake8
flake8: .airflow/sentinels/requirements.sentinel ## Run the flake8 agains dags folder
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run --rm test flake8 dags
	@echo Flake 8 OK!s

.PHONY: clean.airflow
clean.airflow: ## Removes .airflow folder and docker containers
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) down
	rm -rf .airflow

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

  airflow:
    depends_on:
      - db          
    build:
      context: $${PWD}
      dockerfile: .airflow/Dockerfile
    working_dir: /code
    env_file: $${PWD}/$(AIRFLOW_DOCKER_ENVIRONMENT_VARS)
    ports:
      - "8080:8080"
    volumes:
      - "$${PWD}/:/code"
      - logs-volume:/root/airflow/logs/
    command: airflow webserver

  scheduler:
    depends_on:
      - db          
    build:
      context: $${PWD}
      dockerfile: .airflow/Dockerfile
    working_dir: /code
    env_file: $${PWD}/$(AIRFLOW_DOCKER_ENVIRONMENT_VARS)
    volumes:
      - "$${PWD}/:/code"
      - logs-volume:/root/airflow/logs/
    command: airflow scheduler

  test:
    build:
      context: $${PWD}
      dockerfile: .airflow/Dockerfile
    working_dir: /code
    volumes:
      - "$${PWD}/:/code"

volumes:
  logs-volume:
endef
export AIRFLOW_DOCKER_COMPOSE

define AIRFLOW_DOCKERFILE
FROM python:3.6.6

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
.airflow:
	mkdir -p .airflow

# Create a sentinels folder. Sentinel files are empty files
# used to make sure targets have run and skip them.
# Other targets depends on these sentinel files
.airflow/sentinels: .airflow
	mkdir -p .airflow/sentinels

# This creates the docker-compose.yml file.
.airflow/docker-compose.yml: .airflow
	echo "$$AIRFLOW_DOCKERFILE" > .airflow/Dockerfile
	echo "$$AIRFLOW_DOCKER_COMPOSE" > .airflow/docker-compose.yml

# Ensure that we have started the PostgreSQL and ran airflow initdb
.airflow/sentinels/db-init.sentinel: .airflow/sentinels/requirements.sentinel
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) up -d db
	# Wait for postgreSQL to start
	sleep 5
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run --rm airflow airflow initdb
	touch $@

# Ensure that python requirements have run.
# Will rerun on changes on requirements.txt
.airflow/sentinels/requirements.sentinel: $(AIRFLOW_REQUIREMENTS_TXT) .airflow/docker-compose.yml .airflow/sentinels/airflow-env-vars.properties.sentinel
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) build
	touch $@

# Docker environment file
# Various AIRFLOW settings and url to database
$(AIRFLOW_DOCKER_ENVIRONMENT_VARS): .airflow/sentinels
	echo AIRFLOW__CORE__EXECUTOR=LocalExecutor > $@
	echo AIRFLOW__CORE__SQL_ALCHEMY_CONN=postgresql+psycopg2://airflow:airflow@db:5432/airflow >> $@
	echo AIRFLOW__CELERY__RESULT_BACKEND=db+postgresql://airflow:airflow@db:5432/airflow >> $@
	echo AIRFLOW__CORE__DAGS_FOLDER=/code/dags >> $@
	echo AIRFLOW__CORE__LOAD_EXAMPLES=False >> $@

# Listens for local changes on airflow-env-vars.properties, if exists.
.airflow/sentinels/%.sentinel: airflow-env-vars.properties
	cat ${PWD}/airflow-env-vars.properties >> $(AIRFLOW_DOCKER_ENVIRONMENT_VARS) || echo "Skipping airflow-environment-variables.properties"
	touch $@

.airflow/sentinels/airflow-env-vars.properties.sentinel: $(AIRFLOW_DOCKER_ENVIRONMENT_VARS)

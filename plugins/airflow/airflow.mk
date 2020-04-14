.EXPORT_ALL_VARIABLES:
AIRFLOW_WORKFOLDER=.airflow
AIRFLOW_DOCKER_COMPOSE_FILE=$(AIRFLOW_WORKFOLDER)/docker-compose.yml
AIRFLOW_DOCKER_ENVIRONMENT_VARS=$(AIRFLOW_WORKFOLDER)/docker-environment-variables.properties
AIRFLOW_SENTINELS_FOLDER=$(AIRFLOW_WORKFOLDER)/sentinels
COMPOSE_PROJECT_NAME=$(notdir $(CURDIR))

ifndef AIRFLOW_VERSION
AIRFLOW_VERSION := 1.10.6
endif

ifndef AIRFLOW_DOCKER_IMAGE
AIRFLOW_DOCKER_IMAGE := unacast/airflow:$(AIRFLOW_VERSION)
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
AIRFLOW_DAGS_FOLDER := dags
endif

ifndef AIRFLOW_REQUIREMENTS_TXT
AIRFLOW_REQUIREMENTS_TXT := requirements.txt
endif

.PHONY: airflow.start
airflow.start: $(AIRFLOW_SENTINELS_FOLDER)/variables-imported.sentinel ## Start Airflow server
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) up -d db
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) up -d webserver
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) up -d scheduler

.PHONY: airflow.stop
airflow.stop: $(AIRFLOW_WORKFOLDER)/docker-compose.yml ## Stop running Airflow server
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) stop

.PHONY: airflow.logs
airflow.logs: $(AIRFLOW_WORKFOLDER)/docker-compose.yml ## Tail the local logs
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) logs --follow

.PHONY: airflow.test
airflow.test: $(AIRFLOW_WORKFOLDER)/docker-compose.yml ## Run the tests found in /test
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run --rm -e PYTHONPATH=$(AIRFLOW_DAGS_FOLDER):test test pytest

.PHONY: airflow.flake8
airflow.flake8: $(AIRFLOW_WORKFOLDER)/docker-compose.yml ## Run the flake8 agains dags folder
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run --rm test flake8 $(AIRFLOW_DAGS_FOLDER)
	@echo Flake 8 OK!s

.PHONY: airflow.clean
airflow.clean: ## Removes .airflow folder and docker containers
	$(info Removing containers)
	docker ps -a --filter "name=$(COMPOSE_PROJECT_NAME)_" --format "{{.Names}}" | xargs docker rm -f
	$(info Deleting $(AIRFLOW_WORKFOLDER))
	rm -rf $(AIRFLOW_WORKFOLDER)

.PHONY: airflow.error
airflow.error: $(AIRFLOW_SENTINELS_FOLDER)/variables-imported.sentinel ## List all dags, and filter errors
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run webserver airflow list_dags | grep -B5000 "DAGS"

.PHONY: airflow.build
airflow.build: $(AIRFLOW_WORKFOLDER)/docker-compose.yml ## Rebuild docker images with --no-cache. Useful for debugging
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) build --no-cache --force-rm --pull

.PHONY: airflow.rm
airflow.rm: $(AIRFLOW_WORKFOLDER)/docker-compose.yml ## Remove docker images. Useful fordebugging
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) rm

.PHONY: airflow.venv
airflow.venv: ## Create a virtual environment folder for Code-completion and tests inside your IDE
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
      - data-volume:/root/airflow/logs/
      - data-volume:/data/
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
      - data-volume:/root/airflow/logs/
      - data-volume:/data/
    command: airflow scheduler

  test:
    build:
      context: $${PWD}
      dockerfile: $(AIRFLOW_WORKFOLDER)/Dockerfile
    working_dir: /code
    volumes:
      - "$${PWD}/:/code"

volumes:
  data-volume:
endef
export AIRFLOW_DOCKER_COMPOSE

define AIRFLOW_DOCKERFILE
FROM $(AIRFLOW_DOCKER_IMAGE)

ADD $(AIRFLOW_REQUIREMENTS_TXT) /tmp/requirements.txt
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

# A "listener" sentinel for changes on the port. We then recreate the docker-compose.yml
$(AIRFLOW_SENTINELS_FOLDER)/airflow_webserver_port_$(AIRFLOW_WEBSERVER_PORT).sentinel: | $(AIRFLOW_SENTINELS_FOLDER)
	$(info Creating sentinel for Webserver port "$(AIRFLOW_WEBSERVER_PORT)")
	rm -f $(AIRFLOW_SENTINELS_FOLDER)/airflow_webserver_port_*.sentinel
	touch $@

# This creates the docker-compose.yml file.
$(AIRFLOW_WORKFOLDER)/docker-compose.yml: $(AIRFLOW_SENTINELS_FOLDER)/airflow_webserver_port_$(AIRFLOW_WEBSERVER_PORT).sentinel \
$(AIRFLOW_DOCKER_ENVIRONMENT_VARS) $(AIRFLOW_REQUIREMENTS_TXT)
	$(info Creating $(AIRFLOW_WORKFOLDER)/Dockerfile)
	echo "$$AIRFLOW_DOCKERFILE" > $(AIRFLOW_WORKFOLDER)/Dockerfile
	$(info Creating $(AIRFLOW_WORKFOLDER)/docker-compose.yml)
	echo "$$AIRFLOW_DOCKER_COMPOSE" > $(AIRFLOW_WORKFOLDER)/docker-compose.yml
	# If requirements.txt have changed we rebuild
	echo "$?" | grep -q "$(AIRFLOW_REQUIREMENTS_TXT)" && docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) build

# Ensure that we have started the PostgreSQL and ran airflow initdb
$(AIRFLOW_SENTINELS_FOLDER)/db-init.sentinel: $(AIRFLOW_WORKFOLDER)/docker-compose.yml
	echo Starting PostgreSQL container
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) up -d db
	# Wait for postgreSQL to start
	sleep 5
	echo Initializing airflow Postgres database
	docker-compose -f ${AIRFLOW_DOCKER_COMPOSE_FILE} run --rm -e AIRFLOW__CORE__DAGS_FOLDER=/tmp/ webserver airflow initdb
	touch $@

# TODO: Find a way to listen to changes in $(AIRFLOW_VARIABLES) file.
$(AIRFLOW_SENTINELS_FOLDER)/variables-imported.sentinel: $(AIRFLOW_SENTINELS_FOLDER)/db-init.sentinel
	echo Import airflow variables from $(AIRFLOW_VARIABLES)
	if [ -f "$(AIRFLOW_VARIABLES)" ]; then \
	 	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run --rm webserver airflow variables -i /code/$(AIRFLOW_VARIABLES); \
	fi
	$(info Done importing variables)
	touch $@

# Docker environment file
# Various AIRFLOW settings and url to database
$(AIRFLOW_DOCKER_ENVIRONMENT_VARS): | $(AIRFLOW_WORKFOLDER)
	echo AIRFLOW__CORE__EXECUTOR=LocalExecutor > $@
	echo AIRFLOW__CORE__SQL_ALCHEMY_CONN=postgresql+psycopg2://airflow:airflow@db:5432/airflow >> $@
	echo AIRFLOW__CELERY__RESULT_BACKEND=db+postgresql://airflow:airflow@db:5432/airflow >> $@
	echo AIRFLOW__CORE__DAGS_FOLDER=$(AIRFLOW_DAGS_FOLDER) >> $@
	echo 'AIRFLOW__CORE__FERNET_KEY=rSbqA7rweQEHr0qi6rjzJHKUc2zxUqbEypFSk3Qt3ms=' >> $@
	echo AIRFLOW__CORE__LOAD_EXAMPLES=False >> $@
	echo AIRFLOW__WEBSERVER__EXPOSE_CONFIG=True >> $@
	if [ -f "airflow-env-vars.properties" ]; then \
		cat ${PWD}/airflow-env-vars.properties >> $@; \
	fi

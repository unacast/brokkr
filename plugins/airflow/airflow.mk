.EXPORT_ALL_VARIABLES:
AIRFLOW_WORKFOLDER ?= .airflow
AIRFLOW_DOCKER_COMPOSE_FILE ?=$(AIRFLOW_WORKFOLDER)/docker-compose.yml
AIRFLOW_DOCKER_ENVIRONMENT_VARS=$(AIRFLOW_WORKFOLDER)/docker-environment-variables.properties
AIRFLOW_DOCKER_ENVIRONMENT_VARS_SENTINEL=$(AIRFLOW_SENTINELS_FOLDER)/docker-env-vars-created.sentinel
AIRFLOW_SENTINELS_FOLDER=$(AIRFLOW_WORKFOLDER)/sentinels
COMPOSE_PROJECT_NAME=$(notdir $(CURDIR))
AIRFLOW_DOCKERFILE=$(AIRFLOW_WORKFOLDER)/Dockerfile
AIRFLOW_ENV_VARS_HASH=$(shell echo '$(AIRFLOW_ENVIRONMENT_VARS)' | md5sum | cut -d ' ' -f1)
AIRFLOW_VARIABLES_SENTINEL=$(AIRFLOW_SENTINELS_FOLDER)/variables-imported.sentinel
AIRFLOW_VERSION_SENTINEL=$(AIRFLOW_SENTINELS_FOLDER)/airflow_version_$(shell echo '$(AIRFLOW_ENVIRONMENT_VARS)' | md5sum | cut -d ' ' -f1).sentinel
BROKKR_AIRFLOW_PLUGIN_VERSION=$(shell echo $(BROKKR_PLUGINS) | grep -o1 -Ei "airflow/airflow@([0-9a-z\.]+)" | cut -d "@" -f2)
AIRFLOW_VERSION ?= 1.10.6
AIRFLOW_DOCKER_IMAGE ?= unacast/airflow:$(AIRFLOW_VERSION)
AIRFLOW_VIRTUAL_ENV_FOLDER ?= .venv
AIRFLOW_WEBSERVER_PORT ?= 8080
AIRFLOW_VARIABLES ?= $(AIRFLOW_SENTINELS_FOLDER)/airflow-variables.json
AIRFLOW_DAGS_FOLDER ?= dags
AIRFLOW_TESTS_FOLDER ?= tests
AIRFLOW_REQUIREMENTS_TXT ?= $(AIRFLOW_WORKFOLDER)/requirements.txt
AIRFLOW_ENVIRONMENT_VARS ?= $(AIRFLOW_WORKFOLDER)/docker-environment-variables.extra.properties

.PHONY: airflow.start
airflow.start: $(AIRFLOW_VARIABLES_SENTINEL) ## Start Airflow server
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
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run --rm -e PYTHONPATH=$(AIRFLOW_DAGS_FOLDER):$(AIRFLOW_TESTS_FOLDER) test pytest -rA $(AIRFLOW_TESTS_FOLDER)

.PHONY: airflow.flake8
airflow.flake8: $(AIRFLOW_WORKFOLDER)/docker-compose.yml ## Run the flake8 agains dags folder
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run --rm test flake8 $(AIRFLOW_DAGS_FOLDER)
	@echo Flake 8 OK!s

.PHONY: airflow.clean
airflow.clean: ## Removes .airflow folder and docker containers
	echo Removing containers
	docker ps -a --filter "name=$(COMPOSE_PROJECT_NAME)_" --format "{{.Names}}" | xargs docker rm -f
	echo Removing data volume
	docker volume ls --format "{{.Name}}" --filter "name=$(COMPOSE_PROJECT_NAME)_data-volume" | xargs docker volume rm
	$(info Deleting $(AIRFLOW_WORKFOLDER))
	rm -rf $(AIRFLOW_WORKFOLDER)

.PHONY: airflow.error
airflow.error: $(AIRFLOW_VARIABLES_SENTINEL) ## List all dags, and filter errors
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run webserver airflow list_dags | grep -B5000 "DAGS"

.PHONY: airflow.build
airflow.build: $(AIRFLOW_WORKFOLDER)/docker-compose.yml ## Rebuild docker images with --no-cache. Useful for debugging
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) build --no-cache --force-rm --pull

.PHONY: airflow.rm
airflow.rm: $(AIRFLOW_WORKFOLDER)/docker-compose.yml ## Remove docker images. Useful fordebugging
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) rm

.PHONY: airflow.venv
airflow.venv: $(AIRFLOW_REQUIREMENTS_TXT) ## Create a virtual environment folder for Code-completion and tests inside your IDE
	virtualenv -p python3 $(AIRFLOW_VIRTUAL_ENV_FOLDER); \
	source $(AIRFLOW_VIRTUAL_ENV_FOLDER)/bin/activate; \
	export AIRFLOW_GPL_UNIDECODE="yes"; \
	pip install -r $(AIRFLOW_REQUIREMENTS_TXT);

.PHONY: airflow.pip_install
airflow.pip_install: $(AIRFLOW_REQUIREMENTS_TXT) ## Run pip install -r requirements.txt. This is helpful in a CI environment, where we don't use Docker.
	SLUGIFY_USES_TEXT_UNIDECODE=yes pip install -r $(AIRFLOW_REQUIREMENTS_TXT)



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
      dockerfile: $(AIRFLOW_DOCKERFILE)
    working_dir: /code
    env_file:
      - $${PWD}/$(AIRFLOW_DOCKER_ENVIRONMENT_VARS)
      - $${PWD}/$(AIRFLOW_ENVIRONMENT_VARS)
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
      dockerfile: $(AIRFLOW_DOCKERFILE)
    working_dir: /code
    env_file:
      - $${PWD}/$(AIRFLOW_DOCKER_ENVIRONMENT_VARS)
      - $${PWD}/$(AIRFLOW_ENVIRONMENT_VARS)
    volumes:
      - "$${PWD}/:/code"
      - data-volume:/root/airflow/logs/
      - data-volume:/data/
    command: airflow scheduler

  test:
    build:
      context: $${PWD}
      dockerfile: $(AIRFLOW_DOCKERFILE)
    working_dir: /code
    volumes:
      - "$${PWD}/:/code"

volumes:
  data-volume:
endef
# Export the variable for use in targets down below
export AIRFLOW_DOCKER_COMPOSE

define AIRFLOW_DOCKERFILE_TEMPLATE
FROM $(AIRFLOW_DOCKER_IMAGE)

ADD $(AIRFLOW_REQUIREMENTS_TXT) /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt
endef
# Export the variable for use in targets down below
export AIRFLOW_DOCKERFILE_TEMPLATE

############################################################
# These are various pre-steps that are needed before running
# the webserver, flake8 or tests
############################################################

# Create the working folder. This is where the intermediate files like docker-compose.yml
# and sentinel files are stored.
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

# Sentinel for the Airflow version. We need to recreate the docker-compose.yml when changed
$(AIRFLOW_VERSION_SENTINEL): | $(AIRFLOW_SENTINELS_FOLDER)
	echo Creating sentinel for AIRFLOW VERSION $(AIRFLOW_VERSION)
	rm -f $(AIRFLOW_SENTINELS_FOLDER)/airflow_version_*
	echo $(AIRFLOW_VERSION) >> $@

# This creates the Airflow dockerfile, if the user has not added his own
$(AIRFLOW_DOCKERFILE):
	$(info Creating $(AIRFLOW_DOCKERFILE))
	echo "$$AIRFLOW_DOCKERFILE_TEMPLATE" > $(AIRFLOW_DOCKERFILE)

$(AIRFLOW_DOCKER_ENVIRONMENT_VARS):
	$(info Creating $(AIRFLOW_DOCKER_ENVIRONMENT_VARS))
	echo AIRFLOW__CORE__EXECUTOR=LocalExecutor > $(AIRFLOW_DOCKER_ENVIRONMENT_VARS)
	echo AIRFLOW__CORE__SQL_ALCHEMY_CONN=postgresql+psycopg2://airflow:airflow@db:5432/airflow >> $(AIRFLOW_DOCKER_ENVIRONMENT_VARS)
	echo AIRFLOW__CELERY__RESULT_BACKEND=db+postgresql://airflow:airflow@db:5432/airflow >> $(AIRFLOW_DOCKER_ENVIRONMENT_VARS)
	echo AIRFLOW__CORE__DAGS_FOLDER=/code/$(AIRFLOW_DAGS_FOLDER) >> $(AIRFLOW_DOCKER_ENVIRONMENT_VARS)
	echo 'AIRFLOW__CORE__FERNET_KEY=rSbqA7rweQEHr0qi6rjzJHKUc2zxUqbEypFSk3Qt3ms=' >> $(AIRFLOW_DOCKER_ENVIRONMENT_VARS)
	echo AIRFLOW__CORE__LOAD_EXAMPLES=False >> $(AIRFLOW_DOCKER_ENVIRONMENT_VARS)
	echo AIRFLOW__WEBSERVER__EXPOSE_CONFIG=True >> $(AIRFLOW_DOCKER_ENVIRONMENT_VARS)
	touch $@

# If not a requirements.txt is supplied, we download the version from Brokkr
$(AIRFLOW_REQUIREMENTS_TXT): $(AIRFLOW_WORKFOLDER)
	$(info Downloading requirements.txt for version $(AIRFLOW_VERSION) of Airflow)
	curl --fail -s \
	"https://raw.githubusercontent.com/$(BROKKR_REPO)/$(BROKKR_AIRFLOW_PLUGIN_VERSION)/plugins/airflow/docker/requirements.$(AIRFLOW_VERSION).txt" \
	-o $@;

# This creates the docker-compose.yml file.
$(AIRFLOW_DOCKER_COMPOSE_FILE): $(AIRFLOW_SENTINELS_FOLDER)/airflow_webserver_port_$(AIRFLOW_WEBSERVER_PORT).sentinel \
$(AIRFLOW_ENVIRONMENT_VARS) $(AIRFLOW_DOCKERFILE) $(AIRFLOW_DOCKER_ENVIRONMENT_VARS) \
$(AIRFLOW_VERSION_SENTINEL) $(AIRFLOW_REQUIREMENTS_TXT)
	$(info Creating $(AIRFLOW_DOCKER_COMPOSE_FILE))
	echo "$$AIRFLOW_DOCKER_COMPOSE" > $(AIRFLOW_WORKFOLDER)/docker-compose.yml
	# If requirements.txt or version have changed we rebuild
	echo "$?" | grep -q "$(AIRFLOW_VERSION_SENTINEL)\|$(AIRFLOW_REQUIREMENTS_TXT)" \
		&& docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) build

# Ensure that we have started the PostgreSQL and ran airflow initdb
$(AIRFLOW_SENTINELS_FOLDER)/db-init.sentinel: $(AIRFLOW_DOCKER_COMPOSE_FILE)
	echo Starting PostgreSQL container
	DOCKERFILE=$(AIRFLOW_DOCKERFILE) docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) up -d db
	# Wait for postgreSQL to start
	sleep 5
	echo Initializing airflow Postgres database
	docker-compose -f ${AIRFLOW_DOCKER_COMPOSE_FILE} run --rm -e AIRFLOW__CORE__DAGS_FOLDER=/tmp/ webserver airflow initdb
	touch $@

# If user has not supplied a Airflow variables file, create an empty one
$(AIRFLOW_VARIABLES): $(AIRFLOW_SENTINELS_FOLDER)
	touch $@

# User input of Airflow variables. These are imported into the Airflow db
$(AIRFLOW_VARIABLES_SENTINEL): $(AIRFLOW_SENTINELS_FOLDER)/db-init.sentinel $(AIRFLOW_VARIABLES)
	echo Import airflow variables from $(AIRFLOW_VARIABLES)
	if [ -f "$(AIRFLOW_VARIABLES)" ]; then \
	 	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run --rm webserver airflow variables -i /code/$(AIRFLOW_VARIABLES); \
	fi
	$(info Done importing variables)
	touch $@

# Extra docker environment vars
# This could be a file added to version control for example
# This file is included in the docker-compose
$(AIRFLOW_ENVIRONMENT_VARS): | $(AIRFLOW_SENTINELS_FOLDER)
	touch $@
.EXPORT_ALL_VARIABLES:
AIRFLOW_WORKFOLDER ?= .airflow
AIRFLOW_VARIABLES_SENTINEL=$(AIRFLOW_WORKFOLDER)/variables-imported.sentinel
AIRFLOW_INIT_CHECK_SENTINEL=$(AIRFLOW_WORKFOLDER)/airflow-initiated.sentinel
AIRFLOW_BUILD_SENTINEL=$(AIRFLOW_WORKFOLDER)/airflow-build.sentinel
AIRFLOW_DB_INIT_SENTINEL=$(AIRFLOW_WORKFOLDER)/db-init.sentinel
AIRFLOW_DOCKER_COMPOSE_FILE ?= docker-compose.yml
COMPOSE_PROJECT_NAME=$(notdir $(CURDIR))
BROKKR_AIRFLOW_PLUGIN_VERSION=$(shell echo $(BROKKR_PLUGINS) | grep -o1 -Ei "airflow/airflow@([0-9a-z\._]+)" | cut -d "@" -f2)
AIRFLOW_VERSION ?= "2.2.3"
AIRFLOW_MAJOR_VERSION=$(shell echo ${AIRFLOW_VERSION} | cut -d "." -f 1)
AIRFLOW_DOCKER_IMAGE ?= unacast/airflow:$(AIRFLOW_VERSION)
AIRFLOW_VIRTUAL_ENV_FOLDER ?= .venv
AIRFLOW_VARIABLES_JSON ?= airflow-variables.local.json
AIRFLOW_REQUIREMENTS_TXT ?= requirements.txt
AIRFLOW_REQUIREMENTS_EXTRA_TXT ?= requirements.extra.txt

.PHONY: airflow.start
airflow.start: $(AIRFLOW_BUILD_SENTINEL) $(AIRFLOW_VARIABLES_SENTINEL) ## Start Airflow server
    docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) up -d db
    docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) up -d webserver
    docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) up -d scheduler
    echo "Now running at http://localhost:$(shell grep "AIRFLOW_WEBSERVER_PORT" .env | cut -d "=" -f2)/"

.PHONY: airflow.stop
airflow.stop: $(AIRFLOW_INIT_CHECK_SENTINEL) ## Stop running Airflow server
    docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) stop

.PHONY: airflow.logs
airflow.logs: $(AIRFLOW_INIT_CHECK_SENTINEL) ## Tail the local logs
    docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) logs --follow

.PHONY: airflow.test
airflow.test: $(AIRFLOW_BUILD_SENTINEL) $(AIRFLOW_INIT_CHECK_SENTINEL) ## Run the tests found in /test
    set +e;docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run --rm  test pytest --html=/code/output/report.html --junitxml=/code/output/junit.xml -rA /code/tests; \
    open $${PWD}/output/report.html

.PHONY: airflow.flake8
airflow.flake8:$(AIRFLOW_BUILD_SENTINEL) $(AIRFLOW_INIT_CHECK_SENTINEL) ## Run the flake8 agains dags folder
    docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run -v ${PWD}/.flake8:/code/.flake8 --rm test flake8 /code/dags
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
airflow.error: $(AIRFLOW_INIT_CHECK_SENTINEL) ## List all dags, and filter errors
    docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run webserver airflow list_dags | grep -B5000 "DAGS"

.PHONY: airflow.build
airflow.build: $(AIRFLOW_INIT_CHECK_SENTINEL) ## Rebuild docker images with --no-cache. Useful for debugging
    docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) build --no-cache --force-rm --pull

.PHONY: airflow.rm
airflow.rm: $(AIRFLOW_INIT_CHECK_SENTINEL) ## Remove docker images. Useful fordebugging
    docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) rm

.PHONY: airflow.venv
airflow.venv: $(AIRFLOW_REQUIREMENTS_TXT) $(AIRFLOW_REQUIREMENTS_EXTRA_TXT) $(AIRFLOW_REQUIREMENTS_TEST_TXT) ## Create a virtual environment folder for Code-completion and tests inside your IDE
    virtualenv -p python3 $(AIRFLOW_VIRTUAL_ENV_FOLDER); \
    source $(AIRFLOW_VIRTUAL_ENV_FOLDER)/bin/activate; \
    export AIRFLOW_GPL_UNIDECODE="yes"; \
    pip install -r $(AIRFLOW_REQUIREMENTS_TXT); \
    pip install -r $(AIRFLOW_REQUIREMENTS_EXTRA_TXT);

.PHONY: airflow.pip_install
airflow.pip_install: $(AIRFLOW_REQUIREMENTS_TXT) ## Run pip install -r requirements.txt. This is helpful in a CI environment, where we don't use Docker.
    SLUGIFY_USES_TEXT_UNIDECODE=yes pip install -r $(AIRFLOW_REQUIREMENTS_TXT)

.PHONY: airflow.init
airflow.init: .env ## Initialise Airflow in project
    $(if $(value GOOGLE_DEFAULT_PROJECT),, $(error GOOGLE_DEFAULT_PROJECT environment variable is not set.))
    $(info Downloading requirements.txt for version $(AIRFLOW_VERSION) of Airflow)

    curl --fail -s \
    "https://raw.githubusercontent.com/$(BROKKR_REPO)/$(BROKKR_AIRFLOW_PLUGIN_VERSION)/plugins/airflow/docker/requirements.$(AIRFLOW_VERSION).txt" \
    -o requirements.txt;
    # Add the extra requirements
    touch requirements.extra.txt

    curl --fail -s \
    "https://raw.githubusercontent.com/$(BROKKR_REPO)/$(BROKKR_AIRFLOW_PLUGIN_VERSION)/plugins/airflow/docker/docker-compose.yml" \
    -o docker-compose.yml;

    curl --fail -s \
    "https://raw.githubusercontent.com/$(BROKKR_REPO)/$(BROKKR_AIRFLOW_PLUGIN_VERSION)/plugins/airflow/docker/docker-environment-variables.properties" \
    -o docker-environment-variables.properties;

    curl --fail -s \
    "https://raw.githubusercontent.com/$(BROKKR_REPO)/$(BROKKR_AIRFLOW_PLUGIN_VERSION)/plugins/airflow/docker/Dockerfile" \
    -o Dockerfile;

    echo "AIRFLOW_CONN_GOOGLE_CLOUD_DEFAULT=google-cloud-platform://?extra__google_cloud_platform__project=${GOOGLE_DEFAULT_PROJECT}" >> docker-environment-variables.properties
    echo "AIRFLOW_CONN_BIGQUERY_DEFAULT=google-cloud-platform://?extra__google_cloud_platform__project=${GOOGLE_DEFAULT_PROJECT}" >> docker-environment-variables.properties
    echo "Done init of Airflow"
    echo "Edit personal settings in .env file!"

.env:
    echo "Creating .env file"
    echo "AIRFLOW_WEBSERVER_PORT=8080" >> .env
    echo "DAGS_FOLDER=dags" >> .env
    echo "TESTS_FOLDER=tests" >> .env
    echo "AIRFLOW_VARIABLES=$(AIRFLOW_VARIABLES_JSON)" >> .env


############################################################
# These are various pre-steps that are needed before running
# the webserver, flake8 or tests
############################################################

# Check that we have created the needed files for running Airflow
$(AIRFLOW_INIT_CHECK_SENTINEL):
ifeq (,$(wildcard $(AIRFLOW_DOCKER_COMPOSE_FILE)))
    $(error Could not find $(AIRFLOW_DOCKER_COMPOSE_FILE). Maybe you should run make airflow.init?)
endif
ifeq (,$(wildcard Dockerfile))
    $(error Could not find Dockerfile. Maybe you should run make airflow.init?)
endif
ifeq (,$(wildcard $(AIRFLOW_VARIABLES_JSON)))
    $(error Could not find $(AIRFLOW_VARIABLES_JSON). Maybe you should run make airflow.init?)
endif
ifeq (,$(wildcard $(AIRFLOW_REQUIREMENTS_TXT)))
    $(error Could not find $(AIRFLOW_REQUIREMENTS_TXT). Maybe you should run make airflow.init?)
endif
ifeq (,$(wildcard $(AIRFLOW_REQUIREMENTS_EXTRA_TXT)))
    $(error Could not find $(AIRFLOW_REQUIREMENTS_EXTRA_TXT). Maybe you should run make airflow.init?)
endif
    touch $@

# Import Airflow variables json file
$(AIRFLOW_VARIABLES_SENTINEL): $(AIRFLOW_DB_INIT_SENTINEL) $(AIRFLOW_VARIABLES_JSON)
    echo Import airflow variables from $(AIRFLOW_VARIABLES_JSON)
    if [ -f "$(AIRFLOW_VARIABLES_JSON)" ]; then \
		if [ $(AIRFLOW_MAJOR_VERSION) -eq "2" ]; then \
        	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run --rm -v ${PWD}/$(AIRFLOW_VARIABLES_JSON):/code/airflow-variables.json webserver variables import /code/airflow-variables.json; \
		else \
			docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run --rm -v ${PWD}/$(AIRFLOW_VARIABLES_JSON):/code/airflow-variables.json webserver airflow variables -i /code/airflow-variables.json; \
		fi
    fi
    echo Done importing variables
    touch $@

# Ensure that we have started the MySQL and ran airflow initdb
$(AIRFLOW_DB_INIT_SENTINEL): $(AIRFLOW_INIT_CHECK_SENTINEL)
    echo Starting MySQL container
    docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) up -d db
    # Wait for MySQL to start
    sleep 10
    echo Initializing airflow MySQL database
    if [ $(AIRFLOW_MAJOR_VERSION) -eq "2" ]; then \
        docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run --rm -e AIRFLOW__CORE__DAGS_FOLDER=/tmp/ webserver db init; \
        docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run --rm -e AIRFLOW__CORE__DAGS_FOLDER=/tmp/ webserver users create -e admin@example.org -u airflow -p airflow -r Admin -f airflow -l airflow; \
    else \
        docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run --rm -e AIRFLOW__CORE__DAGS_FOLDER=/tmp/ webserver initdb; \
    fi
    touch $@

$(AIRFLOW_BUILD_SENTINEL): $(AIRFLOW_REQUIREMENTS_EXTRA_TXT) $(AIRFLOW_REQUIREMENTS_TXT)
    mkdir -p $(AIRFLOW_WORKFOLDER)
    docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) build
    touch $@

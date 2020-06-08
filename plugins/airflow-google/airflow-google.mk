# Can be overridden if you for example would like to use a company
# wide id. For example 
# AIRFLOW_GOOGLE_CREDENTIALS_ID=*my-company.com
AIRFLOW_GOOGLE_CREDENTIALS_ID ?=*
AIRFLOW_GOOGLE_CREDENTIALS_FILE ?=$(shell ls ~/.config/gcloud/legacy_credentials/$(AIRFLOW_GOOGLE_CREDENTIALS_ID)/adc.json | head -1)

# Add Google default connections
$(AIRFLOW_SENTINELS_FOLDER)/google-connections.sentinel: $(AIRFLOW_VARIABLES_SENTINEL)
	echo Removing connection google_cloud_default and bigquery_default
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run --rm webserver airflow connections --delete --conn_id=google_cloud_default
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run --rm webserver airflow connections --delete --conn_id=bigquery_default
	echo Adding connection google_cloud_default and bigquery_default
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run --rm webserver airflow connections --add --conn_id=google_cloud_default --conn_type=google_cloud_platform --conn_extra='{"extra__google_cloud_platform__project":"$(GOOGLE_DEFAULT_PROJECT)"}'
	docker-compose -f $(AIRFLOW_DOCKER_COMPOSE_FILE) run --rm webserver airflow connections --add --conn_id=bigquery_default --conn_type=bigquery --conn_extra='{"extra__google_cloud_platform__project":"$(GOOGLE_DEFAULT_PROJECT)"}'
	touch $@

# Make airflow.start dependent on Google connections has been made
airflow.start: $(AIRFLOW_SENTINELS_FOLDER)/google-connections.sentinel

.airflow/google-auth-credentials.json: $(AIRFLOW_DOCKER_ENVIRONMENT_VARS)
	# Copy the desired credentials into the working folder
	echo Copying $(AIRFLOW_GOOGLE_CREDENTIALS_FILE) to .airflow working folder
	$(shell cp $(AIRFLOW_GOOGLE_CREDENTIALS_FILE) $@)
	# Add an environment variable for the Google credentials
	echo GOOGLE_APPLICATION_CREDENTIALS=/code/$@ >> $(AIRFLOW_DOCKER_ENVIRONMENT_VARS)

# Make sure credentials are added to the $(AIRFLOW_DOCKER_ENVIRONMENT_VARS) file
$(AIRFLOW_VARIABLES_SENTINEL): .airflow/google-auth-credentials.json

# Can be overridden if you for example would like to use a company
# wide id. For example 
# AIRFLOW_GOOGLE_CREDENTIALS_ID=*my-company.com
ifndef AIRFLOW_GOOGLE_CREDENTIALS_ID
AIRFLOW_GOOGLE_CREDENTIALS_ID=*
endif

ifndef AIRFLOW_GOOGLE_CREDENTIALS_FILE
AIRFLOW_GOOGLE_CREDENTIALS_FILE=$(shell ls ~/.config/gcloud/legacy_credentials/$(AIRFLOW_GOOGLE_CREDENTIALS_ID)/adc.json | head -1)
endif

.airflow/google-auth-credentials.json: $(AIRFLOW_DOCKER_ENVIRONMENT_VARS)
	# Copy the desired credentials into the working folder 
	$(shell cp $(AIRFLOW_GOOGLE_CREDENTIALS_FILE) $@)
	# Add an environment variable for the Google credentials
	echo GOOGLE_APPLICATION_CREDENTIALS=/code/$@ >> $(AIRFLOW_DOCKER_ENVIRONMENT_VARS)
	

.airflow/sentinels/airflow-env-vars.properties.sentinel: .airflow/google-auth-credentials.json

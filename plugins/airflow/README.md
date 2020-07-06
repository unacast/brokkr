# Airflow
This is a very opinionated way of running Airflow locally. It is opinionated in the way that we run Airflow within Unacast, which heavily utilises the Google Cloud Platform

It is based on docker and consists of:

- A MySQL database backend
- An Airflow webserver
- An Airflow scheduler
- A test container

## Install
First install Brokkr. Then add the Airflow plugin as so
```
BROKKR_PLUGINS = help/help@v0.4.3 airflow/airflow@v0.4.3
```

## Features
- Automatically adds google credentials(~/.config) to the docker-container. So that you can use the various Google Cloud Platform services.
- Creates a Python Virtual Environment for code completion within Visual Studio or IntelliJ. Run `make airflow.venv` to create a `.venv` folder including the requirements found in `requirements.txt` and `requirements.extra.txt`
- Updates docker containers if changes to `requirements.txt` or `requirements.extra.txt`
- Automatically updates the local scheduler and webserver on code changes

## Running
Run `make` to see the various goals. You should receive this:
```
airflow.build                - Rebuild docker images with --no-cache. Useful for debugging
airflow.clean                - Removes .airflow folder and docker containers
airflow.error                - List all dags, and filter errors
airflow.flake8               - Run the flake8 agains dags folder
airflow.init                 - Initialise Airflow in project
airflow.logs                 - Tail the local logs
airflow.pip_install          - Run pip install -r requirements.txt. This is helpful in a CI environment, where we don't use Docker.
airflow.rm                   - Remove docker images. Useful fordebugging
airflow.start                - Start Airflow server
airflow.stop                 - Stop running Airflow server
airflow.test                 - Run the tests found in /test
airflow.venv                 - Create a virtual environment folder for Code-completion and tests inside your IDE
```

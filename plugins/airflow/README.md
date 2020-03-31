# Airflow
This is a very opinionated way of running Airflow locally

It is based on docker and consists of:

- A PostgreSQL database backend
- An Airflow webserver
- An Airflow scheduler
- A test container

## Running
Run `make` to see the various goals. You should receive this:
```
clean.airflow                - Removes .airflow folder and docker containers
flake8                       - Run the flake8 agains dags folder
logs                         - Tail the local logs
start                        - Start Airflow server
stop                         - Stop running Airflow server
test                         - Run the tests found in /test
```

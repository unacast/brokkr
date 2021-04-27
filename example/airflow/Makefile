.SILENT: ;
SHA := `git rev-parse --short HEAD`
BROKKR_PLUGINS := help/help@$(SHA) airflow/airflow@$(SHA)
.DEFAULT_GOAL := help

# Hack for local testing. This would be installed by the install script instead
-include ../../brokkr/brokkr.mk

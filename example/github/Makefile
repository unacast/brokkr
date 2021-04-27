.SILENT: ;
SHA := `git rev-parse --short HEAD`
BROKKR_PLUGINS := help/help@$(SHA) github/github-deploy@$(SHA)
.DEFAULT_GOAL := help

.PHONY: deploy
deploy: ## Calls the deploy function from github/github-deploy
	@echo Deploying
	#$(call deploy, deploy-to-prod)

-include ../../brokkr/brokkr.mk

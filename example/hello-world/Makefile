.SILENT: ;
SHA := `git rev-parse --short HEAD`
BROKKR_PLUGINS := help/help@$(SHA) git/git-info@$(SHA)
.DEFAULT_GOAL := help

.PHONY: hello.world
hello.world: ## Prints hello world
	@echo Hello world

-include ../../brokkr/brokkr.mk

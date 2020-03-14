.SILENT: ;
BROKKR_HOME := /tmp/brokkr
BROKKR_PLUGINS = help
BROKKR_REPO = file:///${PWD}
.DEFAULT_GOAL := help
hei:
	@echo $(BROKKR_HOME)
	@echo $(_BROKKR_TARGETS)

.PHONY: clear
clear: ## Clears local output folders
	rm -r /tmp/brokkr

-include ./brokkr/brokkr.mk

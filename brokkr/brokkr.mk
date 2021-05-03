# BROKKR_REPO is the plugins repository.
# We guess that all non-http(s) plugins to recide here
BROKKR_REPO ?= unacast/brokkr

# The dir where this file recides
_BROKKR_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
# The dir for where to download the dependencies
_BROKKR_PLUGINS_DIR := $(_BROKKR_DIR)plugins
# A hash, and sentinel, of the plugins, so that we can spot changes
_BROKKR_PLUGINS_HASH=$(shell echo '$(BROKKR_PLUGINS)' | sha1sum | cut -d ' ' -f1)
_BROKKR_PLUGINS_SENTINEL := $(_BROKKR_PLUGINS_DIR)/$(_BROKKR_PLUGINS_HASH).sentinel
# The dependencies file, a working file for adding "include" to downloaded plugins
_BROKKR_PLUGINS_MK := $(_BROKKR_PLUGINS_DIR)/plugins.mk

# Create a new sentinel everytime the plugins changes. This triggers a new download.
$(_BROKKR_PLUGINS_SENTINEL):
	mkdir -p $(_BROKKR_PLUGINS_DIR)
	touch $@

# This is the target that downloads the referenced makefiles
# Depends on .brokkr-folder and subfolders for plugins being loaded.
# http(s) url's are converted to a filename safe download path
$(_BROKKR_PLUGINS_MK): .SHELLFLAGS := -c
$(_BROKKR_PLUGINS_MK): $(_BROKKR_PLUGINS_SENTINEL)
	# Clean working dir, except sentinel
	find $(_BROKKR_PLUGINS_DIR) -type f -not -name "`basename $(_BROKKR_PLUGINS_SENTINEL)`" | xargs rm || echo no files to delete
	for var in $(BROKKR_PLUGINS); do \
		plugin_version=`echo $$var | cut -d '@' -f 2`;\
		plugin_path=`echo $$var | cut -d '@' -f 1`; \
		mkdir -p $(_BROKKR_PLUGINS_DIR)/`dirname $$plugin_path`; \
		url="https://raw.githubusercontent.com/$(BROKKR_REPO)/$${plugin_version}/plugins/$${plugin_path}.mk"; \
		echo "Downloading $${url}"; \
		curl --fail -s "$$url" -o $(_BROKKR_PLUGINS_DIR)/$${plugin_path}.mk; \
		url="https://raw.githubusercontent.com/$(BROKKR_REPO)/$${plugin_version}/plugins/$${plugin_path}.sh"; \
		echo "Downloading $${url}"; \
		curl --fail -s "$$url" -o $(_BROKKR_PLUGINS_DIR)/$${plugin_path}.sh; \
		chmod -f +x $(_BROKKR_PLUGINS_DIR)/$${plugin_path}*.sh 2>/dev/null; \
		echo include $(_BROKKR_PLUGINS_DIR)/$${plugin_path}.mk >> $@; \
	done

.PHONY: brokkr.clean
brokkr.clean: ## Clean up the .brokkr folder. Triggers a new download of plugins.
	rm -r $(_BROKKR_PLUGINS_DIR)

.PHONY: brokkr.update
brokkr.update: ## Download latest Brokkr version
	curl https://raw.githubusercontent.com/$(BROKKR_REPO)/master/scripts/install.sh | bash

-include $(_BROKKR_PLUGINS_MK)

# BROKKR_REPO is the plugins repository.
# We guess that all non-http(s) plugins to recide here
ifndef BROKKR_REPO
BROKKR_REPO := unacast/brokkr
endif

_BROKKR_PLUGIN_PATHS = $(filter-out http%,$(BROKKR_PLUGINS)) $(subst /,!,$(subst :,§,$(filter http%,$(BROKKR_PLUGINS))))
_BROKKR_PLUGIN_SUBFOLDERS = $(addprefix .brokkr/,$(dir $(filter-out http%,$(BROKKR_PLUGINS))))

# Create the local Brokkr folder for storing all plugins
.brokkr:
	mkdir -p .brokkr

# Create all subpaths for plugins
$(_BROKKR_PLUGIN_SUBFOLDERS): .brokkr
	mkdir -p $@

# This is the target that downloads the referenced makefiles
# Depends on .brokkr-folder and subfolders for plugins being loaded.
# http(s) url's are converted to a filename safe download path
.ONESHELL:
$(addprefix .brokkr/,$(_BROKKR_PLUGIN_PATHS)): $(_BROKKR_PLUGIN_SUBFOLDERS)
	@if [ `echo $@ | grep "^\.brokkr\/http.*"` ]; then\
		url=`echo '$@' | sed 's/\.brokkr\///g' | sed 's/§/:/g' | sed 's/!/\//g'`; \
	else \
		plugin_version=`echo $@ | rev | cut -d '-' -f 1 | rev | cut -d '.' -f 1`;\
		plugin_path=`echo $@ | grep -o '/.*' | sed "s/\-$${plugin_version}//g"`; \
		url="https://raw.githubusercontent.com/$(BROKKR_REPO)/$${plugin_version}/plugins$${plugin_path}"; \
	fi;\
	echo "Downloading $${url}";\
	curl --fail -H "Cache-Control: no-cache" -s "$${url}" -o $@;\

.PHONY: clean.brokkr
clean.brokkr: ## Clean up the .brokkr folder. Triggers a new download of plugins.
	rm -r .brokkr

.PHONY: update.brokkr
update.brokkr: ## Download latest Brokkr version
	curl https://raw.githubusercontent.com/judoole/brokkr/master/scripts/install.sh | bash

-include $(addprefix .brokkr/,$(_BROKKR_PLUGIN_PATHS))

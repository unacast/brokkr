# BROKKR_HOME is where we store the downloaded Brokkr plugins
ifndef BROKKR_HOME
BROKKR_HOME := ~/.brokr
endif

# BROKKR_REPO is the plugins repository.
# If it is a Github repo, we try to download the raw content of the mk file.
# If not a Github repo, we use the url provided to curl the content
ifndef BROKKR_REPO
BROKKR_REPO := judoole/brokkr
endif

_BROKKR_PLUGIN_PATHS = $(filter-out http%,$(BROKKR_PLUGINS)) $(subst /,!,$(subst :,§,$(filter http%,$(BROKKR_PLUGINS))))

.brokkr:
	$(info Creating brokkr folder)
	mkdir -p .brokkr

.ONESHELL:
$(addprefix .brokkr/,$(_BROKKR_PLUGIN_PATHS)): .brokkr
	@if [ `echo $@ | grep "^\.brokkr\/http.*"` ]; then\
		url=`echo '$@' | sed 's/\.brokkr\///g' | sed 's/§/:/g' | sed 's/!/\//g'`; \
	else \
		plugin_version=`echo $@ | rev | cut -d '-' -f 1 | rev | cut -d '.' -f 1`;\
		plugin_path=`echo $@ | grep -o '/.*' | sed "s/\-$${plugin_version}//g"`; \
		url="https://raw.githubusercontent.com/$(BROKKR_REPO)/$${plugin_version}/plugins$${plugin_path}"; \
	fi;\
	echo "Downloading $${url}";\
	curl --fail -s "$${url}" -o $@;\

brokkr-clean: ## Clean up the .brokkr folder. Triggers a new download of plugins.
	rm -r .brokkr

-include $(addprefix .brokkr/,$(_BROKKR_PLUGIN_PATHS))

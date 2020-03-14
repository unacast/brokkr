# BROKKR_HOME is where we store the downloaded Brokkr plugins
ifndef BROKKR_HOME
BROKKR_HOME := ~/.brokr
endif

# BROKKR_REPO is the plugins repository.
# If it is a Github repo, we try to download the raw content of the mk file.
# If not a Github repo, we use the url provided to curl the content
ifndef BROKKR_REPO
BROKKR_REPO := https://github.com/judoole/brokkr
endif

_IS_BROKKR_REPO_GITHUB = $(shell echo $(BROKKR_REPO) | grep "https://github.com")
_github_repo_from_url = $(shell echo $(BROKKR_REPO) | grep -o "github.com\/.*" | cut -d "/" -f 2 -f 3)
_raw_github_repo_url := https://raw.githubusercontent.com/$(call _github_repo_from_url)/master/$(1)
_brokkr_plugin_url := $(if $(_IS_BROKKR_REPO_GITHUB), echo $(call _raw_github_repo_url, $(1)), $(BROKKR_REPO))
# TODO: function call for version

_BROKKR_TARGETS = $(addprefix $(BROKKR_HOME)/plugins/, $(BROKKR_PLUGINS))

$(BROKKR_HOME)/plugins:
	@mkdir -p $(BROKKR_HOME)/plugins

$(_BROKKR_TARGETS): $(BROKKR_HOME)/plugins
	$(shell curl -s $(_brokkr_plugin_url)/plugins/`echo "$@" | grep -o "/plugins\/.*" | cut -d "/" -f 3`.mk -o $@)

-include $(_BROKKR_TARGETS)

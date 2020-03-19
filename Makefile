.SILENT: ;
BROKKR_PLUGINS = help/help-c09a208.mk \
		 https://raw.githubusercontent.com/judoole/brokkr/master/example/helloworld.mk
.DEFAULT_GOAL := help

-include ./brokkr/brokkr.mk

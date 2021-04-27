
# This deploy functions takes two parameters:
# - $1: environment (required)
# - $2: task (optional)
# You can also override auto merge by setting AUTO_MERGE=false
# Use this in a rule as so:
# deploy-something:
#   $(call, some-env) <- deploy is the default task
#   $(call, some-env, some-task)
AUTO_MERGE=true
define deploy
	@echo Checking diff local against remote
	$(dir $(abspath $(lastword $(MAKEFILE_LIST))))github-deploy.sh \
	$(strip $1) \
	${AUTO_MERGE} \
	$(strip $(if $2, $2, deploy))
endef

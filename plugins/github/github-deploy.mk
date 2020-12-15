
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
	echo Checking diff local against remote
	# Get latest, so we can diff if there are changes
	git fetch
	# Check if there is staged code or changes. Exit if so
	if git fetch && git diff @{push} --shortstat --exit-code; then \
		gh api repos/:owner/:repo/deployments -H "Accept: application/vnd.github.ant-man-preview+json" \
	               --method POST -F ref=":branch" -F environment="$(strip $1)" -F auto_merge=${AUTO_MERGE} \
         	      -F task="$(strip $(if $2, $2, deploy))"; \
	else \
		echo "There is a git diff ⤴️, exiting..."; \
	fi;
endef

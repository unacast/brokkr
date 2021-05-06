#!/usr/bin/env bash

set -eu -o pipefail

environment=$1
auto_merge=$2
task=$3

if git fetch && git diff @"{push}" --shortstat --exit-code > /dev/null 2>&1; then
		# Trigger the deployment event
		gh api repos/:owner/:repo/deployments -H "Accept: application/vnd.github.ant-man-preview+json" \
		--method POST -F ref=":branch" -F environment="$environment" -F auto_merge="$auto_merge" \
    -F task="$task"

		echo "Looking for active runs..." && sleep 5

		# List all runs for current branch
		branch=$(git branch --show-current)
		run_id=$(gh run list --limit 1 | grep "$branch" | grep -v "completed" | rev | cut -f1 | rev)
		gh run watch "$run_id"
	else
		echo "There is a git diff ⤴️ or no remote branch, exiting..."
	fi;

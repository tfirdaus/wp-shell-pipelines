#!/usr/bin/env bash

# shellcheck source=bin/run.sh
# shellcheck disable=SC1091
source "$(dirname "$0")/shared.sh"

# Check PHP files staged in Git.
PHP_STAGED_FILES=$(diff_files --ext=".php")
if [[ ! -z $PHP_STAGED_FILES ]]; then
	docker_run_test_phpcs
	docker_run_test_phpunit
fi

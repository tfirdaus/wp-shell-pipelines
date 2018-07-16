#!/bin/bash

# shellcheck source=bin/run.sh
# shellcheck disable=SC1091
source "$(dirname "$0")/shared.sh"

# Check PHP files staged in the
PHP_STAGED_FILES=$(diff_files --ext=".php")
if [[ ! -z $PHP_STAGED_FILES ]]; then
	test_phpunit
fi

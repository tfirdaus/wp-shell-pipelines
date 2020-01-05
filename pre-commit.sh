#!/usr/bin/env bash

# shellcheck source=bin/run.sh
# shellcheck disable=SC1091
source "$(dirname "$0")/shared.sh"

# Check PHP files staged in the
PHP_STAGED_FILES=$(diff_files --ext=".php")
if [[ ! -z $PHP_STAGED_FILES ]]; then
	$(dirname "$0")/run-root.sh composer bash -c "$(dirname "$0")/phpcs.sh"
	$(dirname "$0")/run-root.sh wp_test bash -c "$(dirname "$0")/phpunit.sh"
fi

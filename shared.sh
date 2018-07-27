#!/bin/bash

while IFS= read -r line; do
	export "$(echo -e "$line" | sed -e 's/[[:space:]]*$//' -e "s/'//g")"
done < <(grep -e PIPELINES_ .env)

diff_files() {

	for i in "$@"; do
		case $i in
			-e=*|--ext=*)
			EXT_PATTERN="${i#*=}"
			shift
			;;
		esac
	done

	echo "$(git diff --cached --name-only --diff-filter=ACM | grep "${EXT_PATTERN}")"
}

# Run PHPUnit.
test_phpunit() {
	IFS=',' read -ra PHPUNIT_SERVICES <<< "$PIPELINES_PHPUNIT_SERVICE"
	if [[ ${#PHPUNIT_SERVICES[@]} -lt 1 ]]; then
		PHPUNIT_SERVICES=phpunit;
	fi

	for SERVICE in "${PHPUNIT_SERVICES[@]}"; do
		echo -e "\\nRun PHPUnit in $SERVICE";

		docker-compose run --rm "$SERVICE" bash -c "bash $(dirname "$0")/phpunit.sh"
		STATUS=$?

		if [[ "$STATUS" -ge "1" ]]; then
			exit 1;
		fi
	done
}

# Check PHPCS violation.
test_phpcs() {
	IFS=',' read -ra PHPCS_SERVICES <<< "$PIPELINES_PHPCS_SERVICE"
	if [[ ${#PHPCS_SERVICES[@]} -lt 1 ]]; then
		PHPCS_SERVICES=phpcs;
	fi

	for SERVICE in "${PHPCS_SERVICES[@]}"; do
		echo -e "\\nRun PHPCS in $SERVICE";
		docker-compose run --rm "$SERVICE" bash -c "bash $(dirname "$0")/phpcs.sh"
		STATUS=$?

		if [[ "$STATUS" -ge "1" ]]; then
			exit 1;
		fi
	done
}

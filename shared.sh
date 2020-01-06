#!/usr/bin/env bash

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

# An alias command to run "docker-compose run".
# Run a command in a running container as the www-data user.
docker_run() {
	DOCKER_SERVICES=$(docker-compose config --services)

	if [[ ! -z "$1" ]] && [[ $(echo "${DOCKER_SERVICES[@]}" | grep -w "$1") == "$1" ]]; then
		docker-compose run --rm -u www-data "$@"
	else
		docker-compose run --rm -u www-data wordpress "$@"
	fi
}

# An alias command to run "docker-compose run".
# Run a command in a running container as the root.
docker_run_root() {
	DOCKER_SERVICES=$(docker-compose config --services)

	if [[ ! -z "$1" ]] && [[ $(echo "${DOCKER_SERVICES[@]}" | grep -w "$1") == "$1" ]]; then
		docker-compose run --rm "$@"
	else
		docker-compose run --rm wordpress "$@"
	fi
}

# Run PHPUnit testing.
docker_run_test_phpunit() {
	IFS=',' read -ra PHPUNIT_SERVICES <<< "$PIPELINES_PHPUNIT_SERVICE"
	if [[ ${#PHPUNIT_SERVICES[@]} -lt 1 ]]; then
		PHPUNIT_SERVICES=phpunit;
	fi

	for SERVICE in "${PHPUNIT_SERVICES[@]}"; do
		echo -e "\\nRun PHPUnit in $SERVICE";

		docker_run_root "$SERVICE" bash -c "bash $(dirname "$0")/phpunit.sh"
		STATUS=$?

		if [[ "$STATUS" -ge "1" ]]; then
			exit 1;
		fi
	done
}

# Check PHPCS violations.
docker_run_test_phpcs() {
	IFS=',' read -ra PHPCS_SERVICES <<< "$PIPELINES_PHPCS_SERVICE"
	if [[ ${#PHPCS_SERVICES[@]} -lt 1 ]]; then
		PHPCS_SERVICES=phpcs;
	fi

	for SERVICE in "${PHPCS_SERVICES[@]}"; do
		echo -e "\\nRun PHPCS in $SERVICE";
		docker_run_root "$SERVICE" bash -c "bash $(dirname "$0")/phpcs.sh"
		STATUS=$?

		if [[ "$STATUS" -ge "1" ]]; then
			exit 1;
		fi
	done
}

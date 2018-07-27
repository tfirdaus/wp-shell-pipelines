#!/bin/bash

while IFS= read -r line; do
	export "$(echo -e "$line" | sed -e 's/[[:space:]]*$//' -e "s/'//g")"
done < <(grep -e WP_ -e DB_ .env) # Get the "WP_" variables.

# List of services in the Docker Composer file location.
WORDPRESS_SERVICES=$(docker-compose config --services | grep "wordpress_php")

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

# Run PHPUnit in each listed WordPress service in docker-compose.
test_phpunit() {

	for SERVICE in $WORDPRESS_SERVICES; do

		echo -e "\\nRun PHPUnit in $SERVICE";
		docker-compose run --rm "$SERVICE" bash -c "\
		bash ${WP_PROJECT_DIR}/$(dirname "$0")/install-wp-tests.sh $DB_NAME $DB_USER $DB_PASSWORD $DB_HOST latest true; \
		bash ${WP_PROJECT_DIR}/$(dirname "$0")/phpunit.sh"
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

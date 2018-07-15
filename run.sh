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

	PHP_STAGED_FILES=$(diff_files --ext=".php")

	if [[ ! -z $PHP_STAGED_FILES ]]; then
		for SERVICE in $WORDPRESS_SERVICES; do

			echo -e "\\nRun PHPUnit in $SERVICE";
			docker-compose run --rm "$SERVICE" bash -c "\
			bash ${WP_PROJECT_DIR}/$(dirname "$0")/install-wp-tests.sh $DB_NAME $DB_USER $DB_PASSWORD $DB_HOST latest true; \
			bash ${WP_PROJECT_DIR}/$(dirname "$0")/ci-phpunit.sh"

			if [[ $? == 1 ]]; then
				exit $?
			fi
		done
	fi
}

test_phpunit

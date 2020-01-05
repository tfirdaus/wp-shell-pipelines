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
drun() {
	DOCKER_SERVICES=$(docker-compose config --services)

	if [[ ! -z "$1" ]] && [[ $(echo "${DOCKER_SERVICES[@]}" | grep -w "$1") == "$1" ]]; then
		docker-compose run --rm -u www-data "$@"
	else
		docker-compose run --rm -u www-data wordpress "$@"
	fi
}

# An alias command to run "docker-compose run".
# Run a command in a running container as the root.
drun_root() {
	DOCKER_SERVICES=$(docker-compose config --services)

	if [[ ! -z "$1" ]] && [[ $(echo "${DOCKER_SERVICES[@]}" | grep -w "$1") == "$1" ]]; then
		docker-compose run --rm "$@"
	else
		docker-compose run --rm wordpress "$@"
	fi
}

#!/usr/bin/env bash

# shellcheck source=bin/shared.sh
# shellcheck disable=SC1091
source "$(dirname "$0")/shared.sh"

# drun: docker-compose run
docker_run "$@"

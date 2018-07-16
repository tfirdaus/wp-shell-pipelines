#!/bin/bash
# shellcheck source=bin/run.sh
# shellcheck disable=SC1091
source "$(dirname "$0")/shared.sh"

test_phpunit

#!/bin/bash
# shellcheck source=pipelines/shared.sh
# shellcheck disable=SC1091
source "$(dirname "$0")/shared.sh"

test_phpunit

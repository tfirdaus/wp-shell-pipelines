#!/usr/bin/env bash

if [[ $(vendor/bin/phpcs --version) ]]; then
	./vendor/bin/phpcs "$@"
elif [[ $(phpcs --version) ]]; then
	phpcs "$@"
elif [[ $(composer --version) ]]; then

	echo -e "\\nℹ️ PHPCS could not be found locally or globally, but Composer is available."
	echo "🔄 Installing PHPCS through Composer..."

	composer global require "squizlabs/php_codesniffer=*"
	"$(composer global config home)"/vendor/bin/phpcs --version
	"$(composer global config home)"/vendor/bin/phpcs "$@"
fi

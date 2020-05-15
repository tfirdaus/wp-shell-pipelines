#!/usr/bin/env bash

run_phpunit() {
	echo -e "\\n🔋 Starting PHPUnit."

	local WP_TEMPDIR=${TMPDIR-/tmp}
	local WP_TESTS_DIR=${WP_TESTS_DIR-$WP_TEMPDIR/wordpress-tests-lib}
	local WP_CORE_DIR=${WP_CORE_DIR:-$WP_TEMPDIR/wordpress/}

	# Copy the config from the test config to allow us install WordPress Core
	if [[ ! -e "$WP_CORE_DIR"wp-config.php ]]; then
		cp "$WP_TESTS_DIR"/wp-tests-config.php "$WP_CORE_DIR"wp-config.php
	fi

	# Check if the wp-settings.php is present on the config file.
	if [[ -e "$WP_CORE_DIR"wp-config.php ]]; then
		if ! grep -Fxq "require_once(ABSPATH . 'wp-settings.php');" "$WP_CORE_DIR"wp-config.php; then
			sed -i -e "\$arequire_once(ABSPATH . 'wp-settings.php');" "$WP_CORE_DIR"wp-config.php
		fi
	else
		echo -e "\\n⛔️ The wp-config.php file is not present."; exit 1
	fi

	# Install WordPress Core to allow us using wp-cli.
	if ! wp core is-installed --path="$WP_CORE_DIR" --allow-root; then
		echo -e "\\n🚥 Installing WordPress..."
		wp core install --path="$WP_CORE_DIR" --allow-root --skip-email \
			--title=WordPress \
			--url=example.org \
			--admin_user=admin \
			--admin_password=password \
			--admin_email=admin@example.org
	else
		echo "👍 WordPress is already installed."
	fi

	# Get the list of WordPress Plugins
	IFS=',' read -ra WP_PLUGIN_SLUGS <<< "$WP_TESTS_ACTIVATED_PLUGINS"
	if [[ ${WP_PLUGIN_SLUGS[*]} ]]; then
		for WP_PLUGIN_SLUG in "${WP_PLUGIN_SLUGS[@]}"; do
			if ! wp plugin is-installed "$WP_PLUGIN_SLUG" --path="$WP_CORE_DIR" --allow-root; then
				echo -e "\\n🚥 Installing $WP_PLUGIN_SLUG plugin..."
				wp plugin install "$WP_PLUGIN_SLUG" --path="$WP_CORE_DIR" --allow-root
			else
				echo "👍 Plugin '${WP_PLUGIN_SLUG}' is already installed."
			fi
		done
	fi

	# Run PHPUnits
	if [[ "$1" =~ '--coverage-' ]]; then
		if [[ $(vendor/bin/phpunit --version) ]]; then
			phpdbg -qrr vendor/bin/phpunit "$@"
		elif [[ $(phpunit --version) ]]; then
			phpdbg -qrr $(which phpunit) "$@"
		elif [[ $(composer --version) ]]; then
			echo -e "\\nℹ️ PHPUnit could not be found locally or globally, but Composer is available."
			echo -e "🔄Installing PHPUnit through Composer..."

			# WordPress only compatible with PHPUnit 7
			composer global require "phpunit/phpunit=^7"
			phpdbg -qrr "$(composer global config home)"/vendor/bin/phpunit "$@"
		fi
	else
		if [[ $(vendor/bin/phpunit --version) ]]; then
			vendor/bin/phpunit "$@"
		elif [[ $(phpunit --version) ]]; then
			phpunit "$@"
		elif [[ $(composer --version) ]]; then
			echo -e "\\nℹ️ PHPUnit could not be found locally or globally, but Composer is available."
			echo -e "🔄Installing PHPUnit through Composer..."

			# WordPress only compatible with PHPUnit 7
			composer global require "phpunit/phpunit=^7"
			"$(composer global config home)"/vendor/bin/phpunit "$@"
		fi
	fi
}

"$(dirname "$0")/install-wp-tests.sh" "$DB_NAME" "$DB_USER" "$DB_PASSWORD" "$DB_HOST" \
"${WP_TESTS_VERSION-latest}" \
"${SKIP_DB_CREATE-false}" \
&& run_phpunit "$@"

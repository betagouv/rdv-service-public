#!/bin/bash

# run with : ./scripts/devtools/update_playwright.sh

# get gems version before updating
get_gem_version() {
  gem_name="$1"
  bundle info "$gem_name" 2>/dev/null | grep '(' | sed -E 's/.*\(([0-9.]+)\).*/\1/'
}

gem_capybara_playwright_driver_version_before=$(get_gem_version capybara-playwright-driver)
gem_playwright_ruby_client_version_before=$(get_gem_version playwright-ruby-client)

if [[ -z "$gem_capybara_playwright_driver_version_before" || -z "$gem_playwright_ruby_client_version_before" ]]; then
  echo "Error: Unable to determine current versions of capybara-playwright-driver or playwright-ruby-client."
  exit 1
fi

echo "current versions :"
echo "  capybara-playwright-driver = ${gem_capybara_playwright_driver_version_before}"
echo "  playwright-ruby-client     = ${gem_playwright_ruby_client_version_before}"
echo ""

# test if there are new versions available for the gems
echo "Checking for updates to capybara-playwright-driver and playwright-ruby-client..."
outdated_output=$(bundle outdated capybara-playwright-driver playwright-ruby-client)
if echo "$outdated_output" | grep -q "Bundle up to date"; then
  echo "No updates available for capybara-playwright-driver or playwright-ruby-client."
  exit 0
fi

# do the gems update
echo ""
echo "New gem version(s) are available! Updating capybara-playwright-driver and playwright-ruby-client..."
bundle update capybara-playwright-driver playwright-ruby-client
echo ""

# get gems version after updating
gem_capybara_playwright_driver_version_after=$(get_gem_version capybara-playwright-driver)
gem_playwright_ruby_client_version_after=$(get_gem_version playwright-ruby-client)

echo "updated versions :"
echo "  capybara-playwright-driver = ${gem_capybara_playwright_driver_version_before} -> ${gem_capybara_playwright_driver_version_after}"
echo "  playwright-ruby-client     = ${gem_playwright_ruby_client_version_before} -> ${gem_playwright_ruby_client_version_after}"
echo ""

# update playwright npm package
compatible_playwright_npm_package_version=`RAILS_ENV=test bundle exec rails runner 'puts Playwright::COMPATIBLE_PLAYWRIGHT_VERSION.strip'`
if [[ -z "$compatible_playwright_npm_package_version" ]]; then
  echo "Error: Unable to determine compatible playwright npm package version."
  exit 1
fi
echo "(maybe) updating Playwright npm package to version ${compatible_playwright_npm_package_version}..."
yarn add -D "playwright@${compatible_playwright_npm_package_version}"
echo ""

# update playwright browsers
echo "Updating Playwright browsers..."
yarn playwright install chromium --with-deps

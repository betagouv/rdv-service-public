# bundle exec ruby scripts/install_playwright.rb
require "playwright"

playwright_cli_version = Playwright::COMPATIBLE_PLAYWRIGHT_VERSION.strip
puts "playwright_cli_version=#{playwright_cli_version}"
system %(yarn add -D "playwright@#{playwright_cli_version}")
`yarn run playwright install`

WebMock.disable_net_connect!(allow: [
                               "127.0.0.1",
                               "localhost",
                               "www.rdv-solidarites-test.localhost",
                               "chromedriver.storage.googleapis.com", # Autorise à télécharger le binaire chromedriver pour l'exécution de la CI
                             ])

def new_capybara_driver(app, **)
  Capybara::Playwright::Driver.new(
    app,
    browser_type: ENV["PLAYWRIGHT_BROWSER"]&.to_sym || :chromium,
    headless: ENV["HEADLESS"] != "false",
    timeout: 5,
    **
  )
end

Capybara.register_driver(:playwright) { |app| new_capybara_driver(app) }
Capybara.register_driver(:playwright_bypass_csp) { |app| new_capybara_driver(app, bypassCSP: true) }

Capybara.default_max_wait_time = 3

Capybara.javascript_driver = :playwright

Capybara.configure do |config|
  port = 9887 + ENV["TEST_ENV_NUMBER"].to_i
  config.app_host = "http://www.rdv-solidarites-test.localhost:#{port}"
  # config.asset_host = "http://localhost:#{port}"  # for screenshots
  config.server_host = "www.rdv-solidarites-test.localhost"
  config.server_port = port
  config.javascript_driver = :playwright
  config.server = :puma, { Silent: true }
  config.disable_animation = true
  config.save_path = Rails.root.join("tmp/capybara")

  # This is necessary when using Selenium + custom .localhost domain.
  # See: https://stackoverflow.com/a/63973323/2864020
  config.always_include_port = true
end

if ENV["HEADLESS"] == "false"
  Capybara.default_driver = Capybara.javascript_driver
end

# need to reconfigure capybara_save_screenshot with playwright_bypass_csp
# from https://github.com/mattheworiordan/capybara-screenshot/blob/master/lib/capybara-screenshot.rb#L202-L207
Capybara::Screenshot.class_eval do
  register_driver(:playwright_bypass_csp) do |driver, path|
    driver.with_playwright_page do |page|
      page.screenshot(path: path, fullPage: true)
    end
  end
end

RSpec.configure do |config|
  config.after(:each, ignore_js_errors: nil, js: true) do
    logs = page.driver.browser.logs.get(:browser)
    aggregate_failures "javascript errors" do
      logs.each do |log|
        expect(log.level).not_to eq("SEVERE"), log.message
        warn "JS warning in console: #{log.message}" if log.level == "WARNING"
      end
    end
  end

  config.before(:suite) do
    playwright_yarn_version = Rails.root.join("yarn.lock").read[/^playwright@.*\n\s+version\s+"([^"]+)"/, 1]
    unless playwright_yarn_version&.start_with?(Playwright::COMPATIBLE_PLAYWRIGHT_VERSION)
      raise "Playwright gem expects Playwright version #{Playwright::COMPATIBLE_PLAYWRIGHT_VERSION}, but yarn.lock has #{playwright_yarn_version.inspect}"
    end

    playwright_install_list = `node_modules/.bin/playwright install --list`
    unless playwright_install_list.match?(/chromium_headless_shell-\d+/)
      raise "Playwright browser Chromium headless is not installed. Please run 'yarn run playwright install chromium --with-deps'"
    end
  end
end

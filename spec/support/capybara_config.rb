# frozen_string_literal: true

WebMock.disable_net_connect!(allow: [
                               "127.0.0.1",
                               "localhost",
                               "www.rdv-solidarites-test.localhost",
                               "chromedriver.storage.googleapis.com", # Autorise Chromedrive storage pour l'execution de la CI
                             ])

Capybara.register_driver :chrome_headless do |app|
  options = ::Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--window-size=1400,1400")

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.javascript_driver = :chrome_headless

Capybara.register_driver :selenium do |app|
  # these args seem to reduce test flakyness
  args = %w[headless no-sandbox disable-gpu window-size=1500,1000]
  chrome_bin = ENV.fetch("GOOGLE_CHROME_SHIM", nil)
  binary = chrome_bin if chrome_bin
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    capabilities: [Selenium::WebDriver::Chrome::Options.new(
      args: args,
      binary: binary,
      "goog:loggingPrefs": { browser: "ALL" }
    )]
  )
end

Capybara.configure do |config|
  port = 9887 + ENV["TEST_ENV_NUMBER"].to_i
  config.app_host = "http://www.rdv-solidarites-test.localhost:#{port}"
  # config.asset_host = "http://localhost:#{port}"  # for screenshots
  config.server_host = "www.rdv-solidarites-test.localhost"
  config.server_port = port
  config.javascript_driver = :selenium
  config.server = :puma, { Silent: true }
  config.disable_animation = true

  # This is necessary when using Selenium + custom .localhost domain.
  # See: https://stackoverflow.com/a/63973323/2864020
  config.always_include_port = true
end

RSpec.configure do |config|
  config.after(:each, js: true) do |example|
    next unless example.exception # only write logs for failed tests

    FileUtils.mkdir_p "tmp/capybara"
    %i[browser driver].each do |source|
      errors = Capybara.page.driver.browser.logs.get(source)
      fp = "tmp/capybara/chrome.#{example.full_description.parameterize}.#{source}.log"
      File.open(fp, "w") do |f|
        f << "// empty logs" if errors.empty?
        errors.each do |e|
          f << "#{e.timestamp} [#{e.level}]: #{e.message}"
        end
        f << "\n"
      end
    end
  end
end

def expect_page_to_be_axe_clean(path)
  visit path
  expect(page).to have_current_path(path)
  expect(page).to be_axe_clean
end

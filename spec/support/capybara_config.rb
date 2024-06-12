require "selenium-webdriver"

WebMock.disable_net_connect!(
  allow: [
    "127.0.0.1",
    "localhost",
    "www.rdv-solidarites-test.localhost",
  ]
)

# https://www.selenium.dev/documentation/webdriver/browsers/firefox/
Capybara.register_driver :selenium do |app|
  options = Selenium::WebDriver::Options.firefox
  options.args << '-headless'
  # args: %w[headless no-sandbox disable-gpu disable-dev-shm-usage window-size=1500,1000],

  Capybara::Selenium::Driver.new(
    app,
    browser: :firefox,
    options: options
  )
end

Capybara.javascript_driver = :selenium

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

def expect_page_to_be_axe_clean(path)
  visit path # TODO: supprimer en même temps que app/javascript/components/header_tooltip.js
  # Le premier visit permet d'afficher le tooltip du header, et faire qu'il n'apparaisse pas la deuxieme fois
  visit path
  expect(page).to have_current_path(path)
  expect(page).to be_axe_clean
end

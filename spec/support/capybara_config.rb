WebMock.disable_net_connect!(allow: [
                               "127.0.0.1",
                               "localhost",
                               "www.rdv-solidarites-test.localhost",
                               "chromedriver.storage.googleapis.com", # Autorise à télécharger le binaire chromedriver pour l'exécution de la CI
                             ])

Capybara.register_driver :playwright do |app|
  Capybara::Playwright::Driver.new(
    app,
    browser_type: ENV["PLAYWRIGHT_BROWSER"]&.to_sym || :chromium,
    headless: ENV["HEADLESS"] != "false",
    timeout: 5,
    bypassCSP: true # TODO: limit to accessibility specs
  )
end
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

# On force le driver JS lorsqu’on debug des tests E2E, mais ça ne
# fonctionne pas dans tous les cas, il vaut mieux rajouter manuellement js:true
if ENV["HEADLESS"] == "false"
  Capybara.default_driver = Capybara.javascript_driver
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
end

def expect_page_to_be_axe_clean(path, excluding_selector: nil)
  visit path
  expect(page).to have_current_path(path)
  expect_page_to_have_title

  if excluding_selector
    expect(page).to be_axe_clean.excluding(excluding_selector)
  else
    expect(page).to be_axe_clean
  end
end

# Pour des questions d’accessibilité, chaque page doit avoir un titre explicite
# suivi du nom de l’application
def expect_page_to_have_title
  expect(page).to have_title(/.* - RDV Solidarités/)
end

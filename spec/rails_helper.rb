# This file is copied to spec/ when you run 'rails generate rspec:install'
require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
# Add additional requires below this line. Rails is not loaded until this point!

require "sentry/test_helper"

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Rails.root.glob("spec/support/**/*.rb").each { |f| require f }
Rails.root.glob("spec/factories/**/*.rb").each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

OmniAuth.config.test_mode = true

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.include PageSpecHelper
  config.include UnescapeHtmlSpecHelper
  config.include Select2SpecHelper
  config.include ApiSpecHelper, type: :request
  config.extend ApiSpecMacros, type: :request
  config.include ApiSpecSharedExamples, type: :request
  config.include ActiveSupport::Testing::TimeHelpers
  config.include ActiveJob::TestHelper
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Warden::Test::Helpers, type: :feature
  config.include FillInReadOnlyInputHelper, type: :feature
  config.include Sentry::TestHelper
  config.include DeviseRequestSpecHelpers, type: :request
  config.include NotificationsHelper

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    Rack::Attack.enabled = false
  end

  config.around do |example|
    DatabaseCleaner.strategy = if example.metadata[:js]
                                 :truncation
                               else
                                 :transaction
                               end

    DatabaseCleaner.cleaning do
      example.run
    end
  end

  config.before do
    setup_sentry_test

    # Si on fait un require 'paper_trail/frameworks/rspec' comme le recommande la documentation de PaperTrail,
    # on désactive le versionning par défaut, et donc les specs n'ont plus le comportement de la prod
    # Par contre, on a besoin de réinitialiser le whodunnit entre chaque spec pour éviter d'avoir de
    # la pollution sur cet état partagé d'une spec à l'autre
    PaperTrail.request.whodunnit = nil
  end
  config.after { teardown_sentry_test }

  config.after do
    ActionMailer::Base.deliveries.clear
    FactoryBot.rewind_sequences
    Rails.cache.clear
    Redis.with_connection { |redis| redis.del(redis.keys("*")) } # clears custom redis usages
    Warden.test_reset!
    WebMock.reset!
  end
end

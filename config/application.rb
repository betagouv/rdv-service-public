# frozen_string_literal: true

require_relative "boot"

# explode rails/all to be able to exclude sprockets
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_view/railtie"
require "action_mailer/railtie"
require "active_job/railtie"
require "action_cable/engine"
require "action_mailbox/engine"
require "action_text/engine"
require "rails/test_unit/railtie"
# require "sprockets/railtie"
require "tod/core_extensions"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Lapin
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.time_zone = "Paris"

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.available_locales = %i[fr en]
    config.i18n.default_locale = :fr
    config.action_view.raise_on_missing_translations = true
    config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.{rb,yml}")]
    config.action_mailer.preview_path = Rails.root.join("spec/mailers/previews")
    config.active_model.i18n_customize_full_message = true
    config.active_record.schema_format = :sql

    # Devise layout
    config.to_prepare do
      [Devise::RegistrationsController, Devise::SessionsController, Devise::ConfirmationsController, Devise::PasswordsController, Devise::InvitationsController].each do |controller|
        controller.layout "registration"
      end
    end
  end
end

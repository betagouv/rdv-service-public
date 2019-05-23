require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Lapin
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.time_zone = 'Paris'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :fr
    config.action_view.raise_on_missing_translations = true
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]
    config.action_mailer.preview_path = "#{Rails.root}/test/mailers/previews"

    # Devise layout
    config.to_prepare do
      [Devise::RegistrationsController, Devise::SessionsController, Devise::ConfirmationsController, Devise::PasswordsController, Devise::InvitationsController].each do |controller|
        controller.layout 'registration'
      end
      Devise::Mailer.layout 'mailer'
    end
  end
end

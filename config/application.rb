require_relative "boot"

# Selectively load modules instead of requiring rails/all
# require "rails/all"
require "rails"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "action_mailer/railtie"
require "active_job/railtie"

require "tod/core_extensions"
require "dsfr/components"
require_relative "../lib/fallback_error_middleware"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Lapin
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.time_zone = "Paris" # The timezone is also set on the client side for the FullCalendar plugin.
    # You will need to change it there too if you change it here.

    config.i18n.available_locales = %i[fr]
    config.i18n.default_locale = :fr
    config.i18n.raise_on_missing_translations = true
    config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.{rb,yml}")]
    config.action_mailer.preview_path = Rails.root.join("spec/mailers/previews")
    config.active_model.i18n_customize_full_message = true

    config.x.redis_url = ENV.fetch("REDIS_URL") { "redis://localhost:6379" }

    config.active_support.cache_format_version = 7.0

    redis_settings = {
      connect_timeout: 30, # Defaults to 20 seconds
      read_timeout: 1, # Defaults to 1 second
      write_timeout: 1, # Defaults to 1 second
      reconnect_attempts: 1, # Defaults to 0
    }

    config.cache_store = :redis_cache_store, {
      url: config.x.redis_url,
      namespace: "cache",
      **redis_settings,
    }

    config.x.redis_namespace = "app"

    # Avec cette configuration, on crée un cookie qui expire au bout de 8 heures
    # Cette date d'expiration est mise à jour à chaque requête.
    # L'expiration est aussi gérée avec le module Timeoutable de Devise, qui indique le temps entre le login et la déconnexion.
    # L'utilisateur peut être obligé à se reconnecter par Devise::Timeoutable même si le cookie n'a pas expiré.
    config.session_store :cookie_store, key: "_rdv_sp_session", expire_after: 8.hours

    # Devise layout
    config.to_prepare do
      [Devise::RegistrationsController, Devise::SessionsController, Devise::ConfirmationsController, Devise::PasswordsController, Devise::InvitationsController].each do |controller|
        controller.layout "application_agent_config"
      end
    end

    config.x.rack_attack.limit = 50

    config.exceptions_app = routes # Permet les pages d'erreur custom

    config.middleware.insert_before(ActionDispatch::ShowExceptions, ::FallbackErrorMiddleware)
  end
end

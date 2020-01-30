if ENV['SENTRY_DSN_RAILS'].present?
  require 'raven'

  Raven.configure do |config|
    config.dsn = ENV['SENTRY_DSN_RAILS']
    config.environments = ['production', 'staging']
    config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)

    config.excluded_exceptions = [
      'ActionController::InvalidAuthenticityToken',
      'ActiveRecord::RecordNotFound',
      'CGI::Session::CookieStore::TamperedWithCookie',
      'Sinatra::NotFound',
      'ActiveJob::DeserializationError',
    ]
  end
end

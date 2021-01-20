Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN_RAILS"]

  config.excluded_exceptions = [
    "ActionController::InvalidAuthenticityToken",
    "ActiveRecord::RecordNotFound",
    "CGI::Session::CookieStore::TamperedWithCookie",
    "Sinatra::NotFound",
    "ActiveJob::DeserializationError",
  ]
end

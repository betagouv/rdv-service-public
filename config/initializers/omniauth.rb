# frozen_string_literal: true

require "omniauth/strategies/franceconnect"

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, ENV.fetch("GITHUB_APP_ID", nil), ENV.fetch("GITHUB_APP_SECRET", nil), scope: "user:email"

  provider :microsoft_graph, ENV.fetch("AZURE_APPLICATION_CLIENT_ID", nil), ENV.fetch("AZURE_APPLICATION_CLIENT_SECRET", nil),
           scope: %w[offline_access openid email profile User.Read Calendars.ReadWrite]

  provider(
    :franceconnect,
    name: :franceconnect,
    scope: %i[email openid birthdate birthplace given_name family_name birthcountry],
    issuer: "https://#{ENV.fetch('FRANCECONNECT_HOST', nil)}",
    client_options: {
      identifier: ENV.fetch("FRANCECONNECT_APP_ID", nil),
      secret: ENV.fetch("FRANCECONNECT_APP_SECRET", nil),
      redirect_uri: "#{ENV.fetch('HOST', nil)}/omniauth/franceconnect/callback",
      host: ENV.fetch("FRANCECONNECT_HOST", nil),
    }
  )

  on_failure do |env|
    strategy = env["omniauth.error.strategy"].class.name
    error_type = env["omniauth.error.type"]
    error = env["omniauth.error"]

    crumb = Sentry::Breadcrumb.new(
      message: "Omniauth env values",
      data: {
        strategy: strategy,
        error: error,
        error_type: error_type,
        full_env: env.select { |_key, value| value.is_a?(String) },
      }
    )
    Sentry.add_breadcrumb(crumb)

    Sentry.capture_message("Omniauth failed: #{error}", fingerprint: [strategy, error_type])

    OmniauthCallbacksController.action(:failure).call(env)
  end
end

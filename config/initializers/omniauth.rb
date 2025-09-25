require "omniauth-rdv-service-public"

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, ENV.fetch("GITHUB_APP_ID", nil), ENV.fetch("GITHUB_APP_SECRET", nil), scope: "user:email"

  provider :microsoft_graph, ENV.fetch("AZURE_APPLICATION_CLIENT_ID", nil), ENV.fetch("AZURE_APPLICATION_CLIENT_SECRET", nil),
           scope: %w[offline_access openid email profile User.Read Calendars.ReadWrite]

  if ENV["RDV_SERVICE_PUBLIC_OAUTH_APP_ID"]
    provider :rdv_service_public, ENV["RDV_SERVICE_PUBLIC_OAUTH_APP_ID"], ENV["RDV_SERVICE_PUBLIC_OAUTH_APP_SECRET"],
             scope: "write", base_url: ENV["RDV_SERVICE_PUBLIC_OAUTH_BASE_URL"]
  end

  on_failure do |env|
    http_host = env["HTTP_HOST"]
    provider = env["omniauth.error.strategy"].class.name.demodulize

    # NOTE: ne pas utiliser 'auth' dans le nom du contexte sinon Sentry le scrubbe
    Sentry.set_context(:omni_failure, { http_host:, provider: })

    Sentry.capture_exception(env["omniauth.error"])

    OmniauthCallbacksController.action(:failure).call(env)
  end
end

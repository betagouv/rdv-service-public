require "omniauth/strategies/franceconnect"
require "omniauth-rdv-service-public"

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

  # TODO: mettre un if sur la variable d'env qui indique qu'on est sur l'instance historique
  # Pour faire le setup :
  # rails runner scripts/create_oauth_application.rb "RDV Aide Numérique" "http://www.rdv-aide-numerique.localhost:3000/omniauth/rdvservicepublic/callback"
  provider :rdv_service_public, ENV["RDV_SERVICE_PUBLIC_OAUTH_APP_ID"], ENV["RDV_SERVICE_PUBLIC_OAUTH_APP_SECRET"],
           scope: "write", base_url: ENV["RDV_SERVICE_PUBLIC_OAUTH_BASE_URL"]

  on_failure do |env|
    http_host = env["HTTP_HOST"]
    provider = env["omniauth.error.strategy"].class.name.demodulize

    # NOTE: ne pas utiliser 'auth' dans le nom du contexte sinon Sentry le scrubbe
    Sentry.set_context(:omni_failure, { http_host:, provider: })

    Sentry.capture_exception(env["omniauth.error"])

    OmniauthCallbacksController.action(:failure).call(env)
  end
end

# frozen_string_literal: true

require "omniauth/strategies/franceconnect"

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, ENV["GITHUB_APP_ID"], ENV["GITHUB_APP_SECRET"], scope: "user:email"

  provider :microsoft_graph, ENV["AZURE_APPLICATION_CLIENT_ID"], ENV["AZURE_APPLICATION_CLIENT_SECRET"],
           scope: %w[offline_access openid email profile User.Read Calendars.ReadWrite]

  provider(
    :franceconnect,
    name: :franceconnect,
    scope: %i[email openid birthdate birthplace given_name family_name birthcountry],
    issuer: "https://#{ENV['FRANCECONNECT_HOST']}",
    client_options: {
      identifier: ENV["FRANCECONNECT_APP_ID"],
      secret: ENV["FRANCECONNECT_APP_SECRET"],
      redirect_uri: "#{ENV['HOST']}/omniauth/franceconnect/callback",
      host: ENV["FRANCECONNECT_HOST"],
    }
  )

  on_failure do |env|
    env["devise.mapping"] = Devise.mappings[:user]
    OmniauthCallbacksController.action(:failure).call(env)
  end
end

# frozen_string_literal: true

require "omniauth/strategies/franceconnect"

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, ENV["GITHUB_APP_ID"], ENV["GITHUB_APP_SECRET"], scope: "user:email"

  provider(
    :franceconnect,
    name: :franceconnect,
    scope: %i[email openid birthdate birthplace given_name family_name birthcountry],
    issuer: "https://#{ENV['FRANCECONNECT_HOST']}",
    client_options: {
      identifier: ENV["FRANCECONNECT_APP_ID"],
      secret: ENV["FRANCECONNECT_APP_SECRET"],
      redirect_uri: "#{ENV['HOST']}/omniauth/franceconnect/callback",
      host: ENV["FRANCECONNECT_HOST"]
    }
  )

  on_failure do |env|
    env["devise.mapping"] = Devise.mappings[:user]
    SuperAdmins::OmniauthCallbacksController.action(:failure).call(env)
  end
end

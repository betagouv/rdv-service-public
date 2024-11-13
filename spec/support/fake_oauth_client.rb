require "sinatra"
require "omniauth-rdv-service-public"

# Cette classe est une application Sinatra minimaliste qui utilise l'oauth de RDV Service Public pour les tests
class FakeOauthClient < Sinatra::Base
  use OmniAuth::Builder do
    provider :rdv_service_public, "fake_app_id", "fake_app_secret",
             scope: "write", base_url: Capybara.app_host
  end

  set :sessions, true

  # Décommentez cette ligne pour avoir des logs sur stdout
  # enable :logging

  get "/login" do
    status 200
    <<-HTML
    <form action="/omniauth/rdvservicepublic" method="post">
      <button type="submit">Se connecter avec RDV Service Public</button>
    </form
    HTML
  end

  get "/omniauth/rdvservicepublic/callback" do
    email = request.env["omniauth.auth"]["info"]["agent"]["email"]
    access_token = request.env["omniauth.auth"]["credentials"]["token"]

    status 200
    <<-HTML
      OAuth réussi !
      Votre email est #{email}, et votre token est #{access_token}
      <a href="#{Capybara.app_host}#{OmniAuth::Strategies::RdvServicePublic.sign_out_path}">Déconnexion</a>
    HTML
  end
end

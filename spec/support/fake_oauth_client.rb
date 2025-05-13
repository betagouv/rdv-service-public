# Cette classe est une application Sinatra minimaliste qui utilise l'oauth de RDV Service Public pour les tests ou le dev en local
# en local : bundle exec ruby spec/support/fake_oauth_client.rb
# cf docs/interconnexions/oauth.md

require "sinatra"
require "omniauth-rdv-service-public"

class FakeOauthClient < Sinatra::Base
  use OmniAuth::Builder do
    provider :rdv_service_public, "fake_app_id", "fake_app_secret",
             scope: "write", base_url: defined?(Capybara) ? Capybara.app_host : "http://www.rdv-solidarites-test.localhost:4567"
  end

  set :sessions, expire_after: 600 # temps en secondes

  # Décommentez cette ligne pour avoir des logs sur stdout
  # enable :logging

  get "/" do
    status 200
    if session[:email]
      <<-HTML
        Votre email est #{session[:email]}, votre token est #{session[:access_token]}, et votre refresh_token est #{session[:refresh_token]}
        <a href="/logout">Déconnexion</a>
      HTML
    else
      <<-HTML
        <form action="/omniauth/rdvservicepublic" method="post">
          <button type="submit">Se connecter avec RDV Service Public</button>
        </form
      HTML
    end
  end

  get "/omniauth/rdvservicepublic/callback" do
    session[:email] = request.env["omniauth.auth"]["info"]["agent"]["email"]
    session[:access_token] = request.env["omniauth.auth"]["credentials"]["token"]
    session[:refresh_token] = request.env["omniauth.auth"]["credentials"]["refresh_token"]

    redirect to("/")
  end

  get "/logout" do
    session.delete(:email)
    session.delete(:access_token)

    redirect to(Capybara.app_host + OmniAuth::Strategies::RdvServicePublic.sign_out_path("fake_app_id"))
  end

  get "/favicon.ico" do
    status 204
    body ""
  end
end

FakeOauthClient.run! if __FILE__ == $PROGRAM_NAME

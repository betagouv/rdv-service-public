# Ce script remplace une version locale de Mon Suivi Social pour tester les intégrations
# Usage  bundle exec ruby scripts/mon_suivi_social_local.rb
require "sinatra"
require "omniauth-rdv-service-public"

OmniAuth.config.request_validation_phase = nil

# Cette classe est une application Sinatra minimaliste qui utilise l'oauth de RDV Service Public pour les tests
class MonSuiviSocial < Sinatra::Base
  base_url = "http://localhost:3000"
  app_id = "Gcz6Hrp8fmqI-4ubjjsJeTcyZg_JF0v_XYsibL7a_Fg"

  use OmniAuth::Builder do
    provider :rdv_service_public, app_id, "development-kLbob_cr6Z58h9DTHjUvOhi44cImr2QA4XOQZJHKTCg", scope: "write", base_url: base_url
  end

  set :sessions, expire_after: 600 # temps en secondes
  set :port, ENV.fetch("PORT", 3010)

  # Décommentez cette ligne pour avoir des logs sur stdout
  enable :logging

  get "/" do
    status 200
    if session[:email]

      <<-HTML
        <h1>Mon Suivi Social (test)</h1>
        Vous êtes connecté.
        <br />
        <a href="http://www.rdv-mairie.localhost:3000/admin/organisations/configuration">Vérifier ma Configuration sur RDV Service Public</a>
        <br />
        <form method="post" action="/prendre_rdv"><button>Prendre RDV avec Françis Factice</button></form>

        <p>Votre email est #{session[:email]}, votre token est #{session[:access_token]}, et votre refresh_token est #{session[:refresh_token]}</p>

        <a href="/logout">Déconnexion</a>
      HTML
    else
      <<-HTML
        <h1>Mon Suivi Social (test)</h1>
        <form action="/auth/rdvservicepublic" method="post">
          <button type="submit">Se connecter avec RDV Service Public</button>
        </form
      HTML
    end
  end

  get "/francis_factice" do
    status 200
    "Francis Factice est un usager"
  end

  get "/auth/rdvservicepublic/callback" do
    session[:email] = request.env["omniauth.auth"]["info"]["agent"]["email"]
    session[:access_token] = request.env["omniauth.auth"]["credentials"]["token"]
    session[:refresh_token] = request.env["omniauth.auth"]["credentials"]["refresh_token"]

    redirect to("/")
  end

  get "/logout" do
    session.delete(:email)
    session.delete(:access_token)

    redirect to(base_url + OmniAuth::Strategies::RdvServicePublic.sign_out_path(app_id))
  end

  post "/prendre_rdv" do
    response = Faraday.post(
      "#{base_url}/api/v1/rdv_plans",
      {
        user: {
          first_name: "Francis",
          last_name: "Factice",
        },
        dossier_url: "http://localhost:3010/francis_factice",
      }.to_json,
      {
        "Content-Type": "application/json",
        Authorization: "Bearer #{session[:access_token]}",
      }
    )

    parsed_response = JSON.parse(response.body)
    redirect_url = parsed_response.dig("rdv_plan", "url").gsub(".localhost", ".localhost:3000")
    redirect to(redirect_url)
  end

  get "/favicon.ico" do
    status 204
    body ""
  end
end

MonSuiviSocial.run!

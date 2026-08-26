RSpec.describe "rate limiting des endpoints qui acceptent un token de connexion restreinte", type: :request do
  include_context "enable rack-attack"

  let!(:participation) { create(:participation) }
  let(:token) { participation.restricted_auth_token }

  specify "GET /r/:tkn est rate-limité" do
    2.times do
      get rdv_short_from_token_path(token)
      expect(response).not_to redirect_to("/500.html")
    end

    get rdv_short_from_token_path(token)
    expect(response).to redirect_to("/500.html")
    expect(sentry_events.last.exception.values.last.type).to eq("Rack::Attack::ThrottleError")
  end

  specify "GET /r/:id/cr est rate-limité" do
    2.times do
      get creneaux_users_rdv_short_path(id: participation.rdv_id)
      expect(response).not_to redirect_to("/500.html")
    end

    get creneaux_users_rdv_short_path(id: participation.rdv_id)
    expect(response).to redirect_to("/500.html")
    expect(sentry_events.last.exception.values.last.type).to eq("Rack::Attack::ThrottleError")
  end

  specify "GET /r/:id/:tkn est rate-limité" do
    2.times do
      get rdv_short_path(id: participation.rdv_id, tkn: token)
      expect(response).not_to redirect_to("/500.html")
    end

    get rdv_short_path(id: participation.rdv_id, tkn: token)
    expect(response).to redirect_to("/500.html")
    expect(sentry_events.last.exception.values.last.type).to eq("Rack::Attack::ThrottleError")
  end

  specify "GET /users/file_attente/unsubscribe/:token est rate-limité" do
    2.times do
      get users_unsubscribe_file_attente_path(token: token)
      expect(response).not_to redirect_to("/500.html")
    end

    get users_unsubscribe_file_attente_path(token: token)
    expect(response).to redirect_to("/500.html")
    expect(sentry_events.last.exception.values.last.type).to eq("Rack::Attack::ThrottleError")
  end

  specify "GET /prdv est rate-limité" do
    2.times do
      get reprendre_rdv_from_participation_invitation_token_short_path(tkn: token)
      expect(response).not_to redirect_to("/500.html")
    end

    get reprendre_rdv_from_participation_invitation_token_short_path(tkn: token)
    expect(response).to redirect_to("/500.html")
    expect(sentry_events.last.level).to eq(:warning)
    expect(sentry_events.last.exception.values.last.type).to eq("Rack::Attack::ThrottleError")
  end

  specify "GET /prendre_rdv avec un invitation_token en query param est rate-limité" do
    2.times do
      get prendre_rdv_path(invitation_token: token)
      expect(response).not_to redirect_to("/500.html")
    end

    get prendre_rdv_path(invitation_token: token)
    expect(response).to redirect_to("/500.html")
    expect(sentry_events.last.exception.values.last.type).to eq("Rack::Attack::ThrottleError")
  end

  specify "GET /users/rdvs/:id avec un invitation_token en query param et un ID de RDV inventé est rate-limité" do
    2.times do
      get users_rdv_path(123, invitation_token: token)
      expect(response).not_to redirect_to("/500.html")
    end

    get users_rdv_path(123, invitation_token: token)
    expect(response).to redirect_to("/500.html")
    expect(sentry_events.last.exception.values.last.type).to eq("Rack::Attack::ThrottleError")
  end

  specify "GET /users/rdvs/:id/creneaux avec un invitation_token en query param et un ID de RDV inventé est rate-limité" do
    2.times do
      get creneaux_users_rdv_path(123, invitation_token: token)
      expect(response).not_to redirect_to("/500.html")
    end

    get creneaux_users_rdv_path(123, invitation_token: token)
    expect(response).to redirect_to("/500.html")
    expect(sentry_events.last.exception.values.last.type).to eq("Rack::Attack::ThrottleError")
  end

  specify "le compteur de rate-limit est partagé entre endpoints" do
    get rdv_short_from_token_path(token)
    expect(response).not_to redirect_to("/500.html")

    get reprendre_rdv_from_participation_invitation_token_short_path(tkn: token)
    expect(response).not_to redirect_to("/500.html")

    get users_unsubscribe_file_attente_path(token: token)
    expect(response).to redirect_to("/500.html")
    expect(sentry_events.last.exception.values.last.type).to eq("Rack::Attack::ThrottleError")
  end

  specify "/prendre_rdv n'est pas throttlé sans query param invitation_token" do
    4.times do
      get prendre_rdv_path
      expect(response).not_to redirect_to("/500.html")
    end
  end

  specify "/users/rdvs/:id n'est pas throttlé si le query param invitation_token est absent" do
    4.times do
      get users_rdv_path(1)
      expect(response).not_to redirect_to("/500.html")
    end
  end

  specify "/users/rdvs/:id/edit n'est jamais throttlé, même avec invitation_token en query param, car elle ne l'interprète pas" do
    4.times do
      get edit_users_rdv_path(1, invitation_token: token)
      expect(response).not_to redirect_to("/500.html")
    end
  end
end

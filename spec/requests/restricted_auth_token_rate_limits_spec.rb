RSpec.describe "rate limiting des endpoints qui acceptent un token de connexion restreinte", type: :request do
  include_context "enable rack-attack"

  let!(:participation) { create(:participation) }
  let(:token) { participation.restricted_auth_token }
  let(:rdv_id) { participation.rdv_id }

  # Chaque endpoint qui accepte un token de connexion restreinte doit être rate-limité par IP.
  # Rails ajoute un segment de format optionnel `(.:format)` à chaque route et tolère le slash final
  {
    "GET /r/:tkn" => "/r/%<token>s",
    "GET /r/:tkn avec un suffixe .json" => "/r/%<token>s.json",
    "GET /r/:id/cr" => "/r/%<rdv_id>s/cr",
    "GET /r/:id/:tkn" => "/r/%<rdv_id>s/%<token>s",
    "GET /users/file_attente/unsubscribe/:token" => "/users/file_attente/unsubscribe/%<token>s",
    "GET /prdv" => "/prdv?tkn=%<token>s",
    "GET /prdv avec un suffixe .json" => "/prdv.json?tkn=%<token>s",
    "GET /prdv avec un suffixe .html" => "/prdv.html?tkn=%<token>s",
    "GET /prdv avec un slash final" => "/prdv/?tkn=%<token>s",
    "GET /prendre_rdv avec un invitation_token en query param" => "/prendre_rdv?invitation_token=%<token>s",
    "GET /prendre_rdv avec un suffixe .json" => "/prendre_rdv.json?invitation_token=%<token>s",
    "GET /prendre_rdv avec un slash final" => "/prendre_rdv/?invitation_token=%<token>s",
    "GET /users/rdvs/:id avec un invitation_token en query param et un ID de RDV inventé" => "/users/rdvs/123?invitation_token=%<token>s",
    "GET /users/rdvs/:id avec un suffixe .json" => "/users/rdvs/123.json?invitation_token=%<token>s",
    "GET /users/rdvs/:id avec un slash final" => "/users/rdvs/123/?invitation_token=%<token>s",
    "GET /users/rdvs/:id/creneaux avec un invitation_token en query param et un ID de RDV inventé" => "/users/rdvs/123/creneaux?invitation_token=%<token>s",
    "GET /users/rdvs/:id/creneaux avec un suffixe .json" => "/users/rdvs/123/creneaux.json?invitation_token=%<token>s",
    "GET /users/rdvs/:id/creneaux avec un slash final" => "/users/rdvs/123/creneaux/?invitation_token=%<token>s",
  }.each do |description, path_template|
    it "#{description} est rate-limité" do
      path = format(path_template, token:, rdv_id:)

      2.times do
        get path
        expect(response).not_to redirect_to("/500.html")
      end

      get path
      expect(response).to redirect_to("/500.html")
      expect(sentry_events.last.level).to eq(:warning)
      expect(sentry_events.last.exception.values.last.type).to eq("Rack::Attack::ThrottleError")
    end
  end

  specify "le compteur de rate-limit est partagé entre endpoints" do
    get "/r/#{token}"
    expect(response).not_to redirect_to("/500.html")

    get "/prdv?tkn=#{token}"
    expect(response).not_to redirect_to("/500.html")

    get "/users/file_attente/unsubscribe/#{token}"
    expect(response).to redirect_to("/500.html")
    expect(sentry_events.last.exception.values.last.type).to eq("Rack::Attack::ThrottleError")
  end

  # Endpoints qui ne doivent PAS être throttlés : la limite (2 en test) est largement
  # dépassée sans jamais déclencher la redirection vers /500.html.
  {
    "/prendre_rdv sans query param invitation_token" => "/prendre_rdv",
    "/users/rdvs/:id sans query param invitation_token" => "/users/rdvs/1",
    "/users/rdvs/:id/edit, même avec invitation_token en query param, car l'action ne l'interprète pas" => "/users/rdvs/1/edit?invitation_token=%<token>s",
  }.each do |description, path_template|
    it "#{description} n'est pas throttlé" do
      path = format(path_template, token:)

      4.times do
        get path
        expect(response).not_to redirect_to("/500.html")
      end
    end
  end
end

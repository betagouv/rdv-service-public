RSpec.describe "Génération du lien de visioconférence d'un RDV par l'agent", type: :request do
  stub_env_for_proconnect

  let(:organisation) { create(:organisation) }
  let(:agent) { create(:agent, email: "francis.factice@exemple.fr", admin_role_in_organisations: [organisation]) }
  let(:motif) { create(:motif, organisation:, location_type: :visio) }
  let(:rdv) { create(:rdv, organisation:, motif:, lieu: nil, agents: [agent], visio_url_custom: nil) }
  let(:rooms_api_url) { "#{VisioNumerique::CreateRoom::DEFAULT_API_URL}/rooms/" }

  before do
    stub_request(:post, rooms_api_url)
      .to_return(status: 200, body: { url: "https://visio.numerique.gouv.fr/salon" }.to_json, headers: { "Content-Type" => "application/json" })
  end

  def login_with_pro_connect
    code = "IDej8hpYou2rZLsDgTzZ_nMl1aXmNajpByd20dig4e8"
    user_info = {
      "sub" => "ab70770d-1285-46e6-b4d0-3601b49698d4",
      "email" => agent.email,
      "given_name" => "Francis Factice",
      "usual_name" => "Factice",
      "siret" => "13002526500013",
      "idp_id" => "fia1",
      "aud" => "4ec41582-1d60-4f12-a63b-d8abaace16ba",
      "exp" => 1717595030, "iat" => 1717594970, "iss" => "https://fca.integ01.dev-agentconnect.fr/api/v2",
    }
    ProConnectStubs.stub_callback_requests(code, user_info, host: "http://www.example.com")

    get pro_connect_auth_path(user_type: "agent")
    state = Rack::Utils.parse_query(URI.parse(response.headers["Location"]).query)["state"]
    get pro_connect_callback_path(state:, code:)
  end

  context "quand l'agent s'est connecté via ProConnect" do
    before { login_with_pro_connect }

    it "affiche le bouton de génération du lien sur la page du RDV" do
      get admin_organisation_rdv_path(organisation, rdv)

      expect(response.body).to include("Générer le lien de visioconférence")
      expect(response.body).not_to include("Associer mon compte à ProConnect")
    end

    it "crée un salon Visio avec l'access token ProConnect et l'associe au RDV" do
      post create_visio_room_agents_rdv_path(rdv)

      expect(WebMock).to have_requested(:post, rooms_api_url).with(headers: { "Authorization" => "Bearer fake proconnect access token" })
      expect(rdv.reload.visio_url_custom).to eq("https://visio.numerique.gouv.fr/salon")
      expect(response).to redirect_to(admin_organisation_rdv_path(organisation, rdv))
      expect(flash[:success]).to eq("Le lien de visioconférence a été généré")
    end

    it "ne notifie pas les participants" do
      expect { post create_visio_room_agents_rdv_path(rdv) }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
    end

    it "ne remplace pas un lien déjà généré" do
      rdv.update!(visio_url_custom: "https://visio.numerique.gouv.fr/existant")

      post create_visio_room_agents_rdv_path(rdv)

      expect(WebMock).not_to have_requested(:post, rooms_api_url)
      expect(rdv.reload.visio_url_custom).to eq("https://visio.numerique.gouv.fr/existant")
    end

    it "affiche une erreur quand l'API Visio échoue" do
      stub_request(:post, rooms_api_url).to_return(status: 500, body: {}.to_json, headers: { "Content-Type" => "application/json" })

      post create_visio_room_agents_rdv_path(rdv)

      expect(rdv.reload.visio_url_custom).to be_nil
      expect(flash[:error]).to eq("Le lien de visioconférence n'a pas pu être généré, veuillez réessayer")
    end
  end

  context "quand l'agent ne s'est pas connecté via ProConnect" do
    before { login_as(agent, scope: :agent) }

    it "affiche une notice pour associer son compte à ProConnect à la place du bouton" do
      get admin_organisation_rdv_path(organisation, rdv)

      expect(response.body).to include("Associer mon compte à ProConnect")
      expect(response.body).not_to include("Générer le lien de visioconférence")
    end

    it "demande à l'agent de se connecter via ProConnect" do
      post create_visio_room_agents_rdv_path(rdv)

      expect(WebMock).not_to have_requested(:post, rooms_api_url)
      expect(rdv.reload.visio_url_custom).to be_nil
      expect(flash[:error]).to eq("Pour générer le lien de visioconférence, connectez-vous via ProConnect")
    end
  end

  context "quand l'agent n'a pas accès au RDV" do
    before { login_as(create(:agent, basic_role_in_organisations: [create(:organisation)]), scope: :agent) }

    it "ne crée pas de salon" do
      expect { post create_visio_room_agents_rdv_path(rdv) }.to raise_error(ActiveRecord::RecordNotFound)

      expect(WebMock).not_to have_requested(:post, rooms_api_url)
      expect(rdv.reload.visio_url_custom).to be_nil
    end
  end
end

RSpec.describe "Réinitialisation des données (voir l'intro de la doc Swagger)" do
  stub_env_with(DB_SEEDS_USERS_AND_AGENTS_PASSWORD: "Rdvservicepublictest1!")

  before do
    travel_to Time.zone.local(2024, 8, 18, 14, 0, 0)
    load Rails.root.join("db/seeds/visioplainte.rb")
  end

  let(:guichet) { Agent.find_by(last_name: "Guichet 1") }
  let(:orga_gendarmerie) { guichet.organisations.last }

  let!(:rdv) { create(:rdv, organisation: orga_gendarmerie, motif: orga_gendarmerie.motifs.last, agents: [guichet]) }

  context "in a non-staging environnement" do
    include_context "Visioplainte Auth"

    it "doesn't even have the route" do
      expect do
        post "/api/visioplainte/reset", headers: auth_header
      end.to raise_error(ActionController::RoutingError)

      expect(rdv.reload).to be_present
    end
  end

  context "in a staging environnement" do
    stub_env_with(
      VISIOPLAINTE_API_KEY: "visioplainte-staging-api-key-123456",
      FRANCECONNECT_V2_BASE_URL: "https://fcp-low.sbx.dev-franceconnect.fr/api/v2"
    )

    around do |example|
      with_modified_env(RDV_SOLIDARITES_INSTANCE_NAME: "STAGING") do
        Rails.application.reload_routes!
        example.run
      end
      Rails.application.reload_routes!
    end

    context "without authentication" do
      it "returns an error and doesn't delete any data" do
        post "/api/visioplainte/reset", headers: []
        expect(response.status).to eq 401
        expect(rdv.reload).to be_present
      end
    end

    context "with authentication and the proper variables" do
      stub_env_with(
        VISIOPLAINTE_API_KEY: "visioplainte-staging-api-key-123456",
        FRANCECONNECT_V2_BASE_URL: "https://fcp-low.sbx.dev-franceconnect.fr/api/v2"
      )

      let(:auth_header) do
        { "X-VISIOPLAINTE-API-KEY": "visioplainte-staging-api-key-123456" }
      end

      it "resets the data" do
        post "/api/visioplainte/reset", headers: auth_header
        expect(response.status).to eq 200
        expect(Rdv.last).to be_blank
        new_organisation = Organisation.find_by(name: "Plateforme Visioplainte Gendarmerie")
        expect(new_organisation.agents.count).to eq 31
      end
    end
  end
end

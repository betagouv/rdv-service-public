RSpec.describe "Search", type: :request do
  include Rails.application.routes.url_helpers

  describe "GET /" do
    context "without params" do
      it "is successful" do
        get root_path
        expect(response).to be_successful
      end

      it "render adress_selection template" do
        get root_path
        expect(response).to render_template("search/address_selection/_rdv_solidarites")
      end
    end

    context "with connected user" do
      let(:organisation) { create(:organisation) }
      let(:agent) { create(:agent, organisations: [organisation]) }
      let(:user) { create(:user, organisations: [organisation], referent_agents: [agent]) }

      before do
        login_as(user, scope: :user)
      end

      context "with agent_id params" do
        it "render motif_selection template" do
          motif = create(:motif, service: agent.services.first, follow_up: true, organisation: organisation)
          create(:plage_ouverture, agent: agent, motifs: [motif], organisation: organisation)
          get prendre_rdv_path(referent_ids: [agent.id], service: agent.services.first.id, departement: organisation.territory.departement_number)
          expect(response).to render_template("search/_motif_selection")
        end
      end
    end

    context "service selection" do
      let(:territory) { create(:territory, departement_number: "75") }
      let(:organisation) { create(:organisation, territory: territory) }
      let(:motif) { create(:motif, organisation: organisation) }
      let(:other_motif) { create(:motif, organisation: organisation) }
      let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif, other_motif], organisation: organisation) }

      it "show text to invite to select motif" do
        get root_path(departement: "75", city_code: "75056", latitude: "48.859", longitude: "2.347", address: "Paris 75001")
        expect(response.body).to include("Sélectionnez le service avec qui vous voulez prendre un RDV")
      end

      it "shows a hint to help find a rdv with a referent agent in case the user is looking for the service of a follow_up motifs" do
        get root_path(departement: "75", city_code: "75056", latitude: "48.859", longitude: "2.347", address: "Paris 75001")
        expect(response.body).to include("Pour prendre un RDV de suivi avec un de vos agents référent")
      end
    end

    context "motif selection" do
      let(:territory) { create(:territory, departement_number: "75") }
      let(:organisation) { create(:organisation, territory: territory) }
      let(:motif) { create(:motif, organisation: organisation) }
      let(:other_motif) { create(:motif, organisation: organisation, service: motif.service) }
      let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif, other_motif], organisation: organisation) }

      it "show text to invite to select motif" do
        get root_path(departement: "75", city_code: "75056", latitude: "48.859", longitude: "2.347", address: "Paris 75001")
        expect(response.body).to include("Sélectionnez le motif de votre RDV")
      end

      it "shows a hint to help find a rdv with a referent agent in case the user is looking for follow_up motifs" do
        get root_path(departement: "75", city_code: "75056", latitude: "48.859", longitude: "2.347", address: "Paris 75001")
        expect(response.body).to include("Pour prendre un RDV de suivi avec un de vos agents référent")
      end
    end
  end

  describe "GET /prendre_rdv" do
    it "is successful" do
      get prendre_rdv_path
      expect(response).to be_successful
    end
  end
end

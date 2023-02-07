# frozen_string_literal: true

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
      let(:user) { create(:user, organisations: [organisation], agents: [agent]) }

      before do
        login_as(user)
      end

      context "with agent_id params" do
        it "render motif_selection template" do
          motif = create(:motif, service: agent.service, follow_up: true, organisation: organisation)
          create(:plage_ouverture, agent: agent, motifs: [motif], organisation: organisation)
          get prendre_rdv_path(referent_ids: [agent.id], service: agent.service_id, departement: organisation.territory.departement_number)
          expect(response).to render_template("search/_lieu_selection")
        end
      end
    end

    context "service selection" do
      let(:territory) { create(:territory, departement_number: "75") }
      let(:organisation) { create(:organisation, territory: territory) }
      let(:motif) { create(:motif, bookable_publicly: true, organisation: organisation) }
      let(:other_motif) { create(:motif, bookable_publicly: true, organisation: organisation) }
      let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif, other_motif], organisation: organisation) }

      it "show text to invite to select motif" do
        get root_path(departement: "75", city_code: "75056", latitude: "48.859", longitude: "2.347", address: "Paris 75001")
        expect(response.body).to include("Sélectionnez le service avec qui vous voulez prendre un RDV")
      end

      it "show link to user's RDV list and follower's agents" do
        get root_path(departement: "75", city_code: "75056", latitude: "48.859", longitude: "2.347", address: "Paris 75001")
        expect(response.body).to include(users_rdvs_path)
      end
    end

    context "motif selection" do
      let(:territory) { create(:territory, departement_number: "75") }
      let(:organisation) { create(:organisation, territory: territory) }
      let(:motif) { create(:motif, bookable_publicly: true, organisation: organisation) }
      let(:other_motif) { create(:motif, bookable_publicly: true, organisation: organisation, service: motif.service) }
      let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif, other_motif], organisation: organisation) }

      it "show text to invite to select motif" do
        get root_path(departement: "75", city_code: "75056", latitude: "48.859", longitude: "2.347", address: "Paris 75001")
        expect(response.body).to include("Sélectionnez le motif de votre RDV")
      end

      it "show link to user's RDV list and follower's agents" do
        get root_path(departement: "75", city_code: "75056", latitude: "48.859", longitude: "2.347", address: "Paris 75001")
        expect(response.body).to include(users_rdvs_path)
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

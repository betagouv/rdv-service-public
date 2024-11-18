RSpec.describe "Search", type: :feature do
  include Rails.application.routes.url_helpers

  describe "GET /" do
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
          visit prendre_rdv_path(referent_ids: [agent.id], service: agent.services.first.id, departement: organisation.territory.departement_number)
          expect(page).to have_content("Sélectionnez le motif de votre RDV")
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
        visit root_path(departement: "75", city_code: "75056", latitude: "48.859", longitude: "2.347", address: "Paris 75001")
        expect(page).to have_content("Sélectionnez le service avec qui vous voulez prendre un RDV")
      end

      it "shows a hint to help find a rdv with a referent agent in case the user is looking for the service of a follow_up motifs" do
        visit root_path(departement: "75", city_code: "75056", latitude: "48.859", longitude: "2.347", address: "Paris 75001")
        expect(page).to have_content("Pour prendre un RDV de suivi avec un de vos agents référent")
      end
    end

    context "motif selection" do
      let(:territory) { create(:territory, departement_number: "75") }
      let(:organisation) { create(:organisation, territory: territory) }
      let(:motif) { create(:motif, organisation: organisation) }
      let(:other_motif) { create(:motif, organisation: organisation, service: motif.service) }
      let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif, other_motif], organisation: organisation) }

      it "show text to invite to select motif" do
        visit root_path(departement: "75", city_code: "75056", latitude: "48.859", longitude: "2.347", address: "Paris 75001")
        expect(page).to have_content("Sélectionnez le motif de votre RDV")
      end

      it "shows a hint to help find a rdv with a referent agent in case the user is looking for follow_up motifs" do
        visit root_path(departement: "75", city_code: "75056", latitude: "48.859", longitude: "2.347", address: "Paris 75001")
        expect(page).to have_content("Pour prendre un RDV de suivi avec un de vos agents référent")
      end
    end
  end

  describe "GET /prendre_rdv" do
    it "is successful" do
      visit "/prendre_rdv"
      expect(page).to have_content("Prenez rendez-vous en ligne avec votre département")
    end
  end
end

# frozen_string_literal: true

describe "Agent can CRUD motifs" do
  let(:organisation) { create(:organisation) }
  let!(:service) { create(:service, name: "PMI") }
  let!(:motif) { create(:motif, name: "Suivi bonjour", service: service, organisation: organisation) }
  let!(:agent) { create(:agent, service: service, admin_role_in_organisations: [organisation]) }

  before do
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
    click_link "Motifs"
  end

  context "when agent from organisation reach motifs#index" do
    it "can CRUD motifs", js: true do
      expect_page_title("Vos motifs")
      click_link motif.name

      expect(page).to have_content(motif.name)
      click_link "Éditer"

      expect_page_title("Modifier le motif")
      fill_in "Nom", with: "Suivi bonsoir"
      click_button("Enregistrer")

      expect(page).to have_content("Suivi bonsoir")
      click_link("Supprimer")

      expect_page_title("Vos motifs")
      expect(page).to have_content("Vous n'avez pas encore créé de motif.")
      click_link "Créer un motif", match: :first

      expect_page_title("Nouveau motif")
      find("#motif_service_id").find(:option, service.name).select_option
      fill_in "Nom", with: "Suivi bonne nuit"
      fill_in "Couleur", with: "#000"
      click_button "Enregistrer"

      expect_page_title("Vos motifs")
      expect(page).to have_content("Suivi bonne nuit")
    end
  end
end

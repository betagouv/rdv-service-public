RSpec.describe "Les agents peuvent renseigner le statut des rendez-vous pour nous permettre de mesurer notre impact" do
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation], services: [service]) }
  let(:organisation) { create(:organisation) }
  let(:service) { create(:service) }
  let!(:rdv) do
    create(:rdv, :past, status: :unknown, agents: [agent], motif: create(:motif, service: service), organisation: organisation)
  end

  before { login_as(agent, scope: :agent) }

  it "works from the main page", js: true do
    visit root_path
    click_link "1 RDV à renseigner"
    find(".fr-btn", text: "Rendez-vous honoré").click
    sleep 1 # Pour attendre que la requête ajax se finisse
    expect(page).to have_content("Rendez-vous mis à jour")
    expect(rdv.reload.status).to eq("seen")

    # Et on peut faire un reset
    find(".btn", text: "Rendez-vous honoré").click
    find("span", text: "Réinitialiser").click
    sleep 1 # Pour attendre que la requête ajax se finisse
    expect(page).to have_content("Rendez-vous mis à jour")
    expect(rdv.reload.status).to eq("unknown")
  end

  context "for a cancelled rdv" do
    it "works from the main page", js: true do
      visit a_renseigner_admin_organisation_rdvs_path(rdv.organisation)

      find(".fr-btn", text: "Autre").click
      find("span", text: "Annulé à l’initiative du service").click

      sleep 1 # Pour attendre que la requête ajax se finisse
      expect(page).to have_content("Rendez-vous mis à jour")
      expect(rdv.reload.status).to eq("revoked")
    end
  end

  it "works from the rdv details page", js: true do
    visit admin_organisation_rdv_path(rdv.organisation, rdv)
    find(".btn", text: "À renseigner").click
    find("span", text: "Rendez-vous honoré").click
    sleep 1 # Pour attendre que la requête ajax se finisse
    expect(page).to have_content("Rendez-vous mis à jour")
    expect(rdv.reload.status).to eq("seen")

    # Et on peut faire un reset
    find(".btn", text: "Rendez-vous honoré").click
    find("span", text: "Réinitialiser").click
    sleep 1 # Pour attendre que la requête ajax se finisse
    expect(page).to have_content("Rendez-vous mis à jour")
    expect(rdv.reload.status).to eq("unknown")
  end
end

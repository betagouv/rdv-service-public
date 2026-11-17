RSpec.describe "Les agents peuvent renseigner le statut des rendez-vous pour nous permettre de mesurer notre impact" do
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let(:organisation) { create(:organisation) }
  let!(:rdv) do
    create(:rdv, :past, status: :unknown, agents: [agent], motif: create(:motif, organisation:), organisation: organisation)
  end

  before { login_as(agent, scope: :agent) }

  it "works from the main page", js: true do
    visit root_path
    click_link "1 RDV à renseigner"
    find(".fr-btn", text: "Rendez-vous honoré").click
    expect(page).to have_css("#rdv-status-#{rdv.id} .rdv-status-seen")
    expect(page).to have_content("Rendez-vous mis à jour")
    expect(rdv.reload.status).to eq("seen")

    # Et on peut faire un reset
    find(".rdv-status-toggle", text: "Rendez-vous honoré").click
    find("span", text: "Réinitialiser").click
    expect(page).to have_css(".fr-btn", text: "Rendez-vous honoré")
    expect(page).to have_content("Rendez-vous mis à jour")
    expect(rdv.reload.status).to eq("unknown")
  end

  context "for a cancelled rdv" do
    it "works from the main page", js: true do
      visit a_renseigner_admin_organisation_rdvs_path(rdv.organisation)

      find(".fr-btn", text: "Autre").click
      find("span", text: "Annulé à l’initiative du service").click

      expect(page).to have_css("#rdv-status-#{rdv.id} .rdv-status-revoked")
      expect(page).to have_content("Rendez-vous mis à jour")
      expect(rdv.reload.status).to eq("revoked")
    end
  end

  it "works from the rdv details page", js: true do
    visit admin_organisation_rdv_path(rdv.organisation, rdv)
    find(".rdv-status-toggle", text: "À renseigner").click
    find("span", text: "Rendez-vous honoré").click
    expect(page).to have_css("#rdv-status-#{rdv.id} .rdv-status-seen")
    expect(page).to have_content("Rendez-vous mis à jour")
    expect(rdv.reload.status).to eq("seen")

    # Et on peut faire un reset
    find(".rdv-status-toggle", text: "Rendez-vous honoré").click
    find("span", text: "Réinitialiser").click
    expect(page).to have_css("#rdv-status-#{rdv.id} .rdv-status-unknown_past")
    expect(page).to have_content("Rendez-vous mis à jour")
    expect(rdv.reload.status).to eq("unknown")
  end

  context "quand un rendez-vous a plusieurs agents assignés" do
    let(:autre_agent) { create(:agent, basic_role_in_organisations: [organisation]) }
    let!(:rdv_multi_agents) do
      create(:rdv, :past, status: :unknown, agents: [agent, autre_agent], motif: create(:motif, organisation:), organisation:)
    end

    it "affiche le bon compteur et la page ne liste ce RDV qu'une fois" do
      visit root_path
      expect(page).to have_link("2 RDV à renseigner") # il y a aussi le RDV du contexte partagé l.27
      click_on "2 RDV à renseigner"
      expect(page).to have_css("#rdv-#{rdv_multi_agents.id}", count: 1)
    end
  end
end

RSpec.describe "Les agents peuvent renseigner le statut des rendez-vous pour nous permettre de mesurer notre impact" do
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation], services: [service]) }
  let(:organisation) { create(:organisation) }
  let(:service) { create(:service) }
  let!(:rdv) do
    create(:rdv, :past, status: :unknown, agents: [agent], motif: create(:motif, service: service), organisation: organisation)
  end

  it "works", js: true do
    login_as(agent, scope: :agent)
    visit root_path
    expect(page).to have_content "Vous avez 1 rendez-vous à renseigner"
    click_link "Voir ces RDV"
    find(".fr-btn", text: "Rendez-vous honoré").click
    expect(page).to have_content("Rendez-vous mis à jour") # Cet expect permet d'attendre la requête ajax
    expect(rdv.reload.status).to eq("seen")
  end
end

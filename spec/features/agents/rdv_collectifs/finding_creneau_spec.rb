RSpec.describe "Agent can find a creneau for a rdv collectif" do
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
  let!(:motif) do
    create(:motif, :collectif, name: "Atelier participatif", organisation: organisation, service: service)
  end
  let(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let!(:rdv) do
    create(:rdv, motif: motif, organisation: organisation, agents: [agent], max_participants_count: 5, lieu: lieu)
  end

  before { login_as(agent, scope: :agent) }

  specify do
    visit admin_organisation_agent_agenda_path(organisation, agent)
    click_link "Trouver un RDV", match: :first

    select "Atelier participatif", from: "Motif"
    click_button "Afficher les créneaux"

    # The rdv collectif appears in the search results
    expect(page).to have_content("Créneaux disponibles pour atelier participatif")
    expect(page).to have_content("1 participant")
    expect(page).to have_content("4 places restantes")

    click_link "Ajouter un participant"

    expect(page).to have_current_path(edit_admin_organisation_rdvs_collectif_path(rdv.organisation, rdv))
  end

  context "when there are rdvs available in two different lieux" do
    let!(:lieu2) { create(:lieu, organisation: organisation) }
    let!(:rdv2) do
      create(:rdv, motif: motif, organisation: organisation, agents: [agent], max_participants_count: 5, lieu: lieu2)
    end

    it "shows the list of lieux before the list of rdvs" do
      visit admin_organisation_creneaux_search_path(organisation)

      select "Atelier participatif", from: "Motif"
      click_button "Afficher les créneaux"

      expect(page).to have_content("2 lieux proposent des disponibilités")
      click_link("Prochaine disponibilité", match: :first)

      expect(page).to have_content("Créneaux disponibles pour atelier participatif")
    end
  end
end

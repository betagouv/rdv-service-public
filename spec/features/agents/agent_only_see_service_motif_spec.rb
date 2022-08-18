# frozen_string_literal: true

describe "Agent can create a Rdv with creneau search" do
  include UsersHelper

  before do
    login_as(agent, scope: :agent)
  end

  let!(:organisation) { create(:organisation) }
  let!(:lieu) { create(:lieu, organisation: organisation) }

  context "default" do
    let!(:organisation) { create(:organisation) }
    let!(:service) { create(:service) }
    let!(:agent) { create(:agent, first_name: "Alain", last_name: "Tiptop", service: service, basic_role_in_organisations: [organisation]) }
    let!(:motif) { create(:motif, name: "MOTIFAVAILABLE", reservable_online: true, service: service, organisation: organisation) }
    let!(:motif2) { create(:motif, name: "OTHERMOTIF", reservable_online: true, organisation: organisation) }
    let!(:plage_ouverture) { create(:plage_ouverture, :daily, first_day: Date.new(2019, 7, 22), motifs: [motif, motif2], lieu: lieu, agent: agent, organisation: organisation) }

    it "can only see motifs of service", js: true do
      visit admin_organisation_agent_searches_path(organisation)
      expect(page).to have_content("Trouver un RDV")

      expect(page).to have_content("MOTIFAVAILABLE")
      expect(page).not_to have_content("OTHERMOTIF")
      select(motif.name, from: "motif_id")
      click_button("Afficher les créneaux")

      expect(page).to have_content(plage_ouverture.lieu.address)
    end
  end
end

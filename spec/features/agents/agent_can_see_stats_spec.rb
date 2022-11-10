# frozen_string_literal: true

describe "Agent can see stats" do
  let!(:territory1) { create(:territory) }
  let!(:organisation1a) { create(:organisation, territory: territory1) }
  let!(:organisation1b) { create(:organisation, territory: territory1) }
  let!(:agent1) { create(:agent, admin_role_in_organisations: [organisation1a, organisation1b]) }

  let!(:territory2) { create(:territory) }
  let!(:organisation2) { create(:organisation, territory: territory2) }
  let!(:agent2) { create(:agent, basic_role_in_organisations: [organisation2]) }

  let!(:rdv1) { create(:rdv, :past, agents: [agent1], organisation: organisation1a) }
  let!(:rdv2) { create(:rdv, agents: [agent2], organisation: organisation1a) }

  let!(:rdv3) { create(:rdv, agents: [agent1], organisation: organisation1b) }
  let!(:rdv4) { create(:rdv, agents: [agent1], organisation: organisation1b) }
  let!(:rdv5) { create(:rdv, agents: [agent2], organisation: organisation1b) }

  let!(:rdv6) { create(:rdv, agents: [agent2], organisation: organisation2) }

  context "spec for agent1 (admin)" do
    before do
      login_as(agent1, scope: :agent)
      visit admin_organisation_agent_agenda_path(organisation1a, agent1)
    end

    it "displays correct stats for organisation1a" do
      click_link "Statistiques"
      expect(page).to have_content("Statistiques #{organisation1a.name}")
      # rdv2
      expect(page).to have_content("À venir\n1")
      # rdv1 & rdv2
      expect(page).to have_content("RDV créés (2)")
    end

    it "displays correct stats for agent1" do
      click_link "Mes statistiques"
      expect(page).to have_content("Statistiques #{agent1.full_name}")
      # rdv3 & rdv4
      expect(page).to have_content("À venir\n2")
      # rdv1, rdv3 & rdv4
      expect(page).to have_content("RDV créés (3)")
    end
  end

  context "spec for agent2 (basic)" do
    before do
      login_as(agent2, scope: :agent)
      visit authenticated_agent_root_path
    end

    it "displays correct stats for organisation2" do
      click_link "Statistiques"
      expect(page).to have_content("Statistiques #{organisation2.name}")
      # rdv6
      expect(page).to have_content("RDV créés (1)")
    end

    it "displays correct stats for agent2" do
      click_link "Mes statistiques"
      expect(page).to have_content("Statistiques #{agent2.full_name}")
      # rdv2, rdv5 & rdv6
      expect(page).to have_content("RDV créés (3)")
    end
  end
end

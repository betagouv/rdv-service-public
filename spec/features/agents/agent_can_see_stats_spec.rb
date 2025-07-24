RSpec.describe "Agent can see stats" do
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
      visit admin_organisation_planning_agenda_path(organisation1a, agent_id: agent1.id)
      click_link "Statistiques"
    end

    it "displays correct stats for organisation1a" do
      expect(page).to have_content("Statistiques de #{organisation1a.name}")
      # rdv2
      expect(page).to have_content("À venir\n1")
      # rdv1 & rdv2
      expect(page).to have_content("RDV créés (2)")
    end
  end

  context "spec for agent2 (basic)" do
    before do
      login_as(agent2, scope: :agent)
      visit authenticated_agent_root_path
      click_link "Statistiques"
    end

    it "displays correct stats for organisation2" do
      expect(page).to have_content("Statistiques de #{organisation2.name}")
      # rdv6
      expect(page).to have_content("RDV créés (1)")
    end
  end
end

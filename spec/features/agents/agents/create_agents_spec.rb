RSpec.describe "Agent can create another agent" do
  let(:territory) { create(:territory) }
  let(:organisation1) { create(:organisation, territory: territory) }
  let(:organisation2) { create(:organisation, territory: territory) }
  let(:agent) { create(:agent, admin_role_in_organisations: [organisation1, organisation2]) }

  before { login_as(agent, scope: :agent) }

  context "in two different organisations" do
    specify do
      visit admin_organisation_agents_path(organisation1)
      click_link("Ajouter un agent", match: :first)
      fill_in("Email", with: "bob@test.com")
      select(agent.services.first.name, from: "Services")
      click_button("Envoyer une invitation")
      expect(Agent.count).to eq(2)

      visit admin_organisation_agents_path(organisation2)
      click_link("Ajouter un agent", match: :first)
      fill_in("Email", with: "bob@test.com")
      click_button("Envoyer une invitation")
      expect(Agent.count).to eq(2)

      expect(page).to have_content("Invitations en cours")
      expect(organisation2.reload.agents.count).to eq 2
    end
  end
end

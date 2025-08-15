RSpec.describe "Activer et désactiver les services pour les agents" do
  before { login_as(agent, scope: :agent) }

  let(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, service: nil, admin_role_in_organisations: [organisation]) }

  before do
    AgentTerritorialAccessRight.create!(agent:, territory: organisation.territory,
                                        allow_to_manage_access_rights: true)
  end

  describe "sans service" do
    let!(:other_agent) { create(:agent, service: nil, basic_role_in_organisations: [organisation]) }

    it "n'affiche jamais les infos des service" do
      visit admin_organisation_agents_path(organisation_id: organisation.id)
      expect(page).not_to have_content "Service"

      visit new_admin_organisation_agent_path(organisation_id: organisation.id)
      expect(page).not_to have_content "Service"

      visit edit_admin_organisation_agent_path(organisation_id: organisation.id, id: agent.id)
      expect(page).not_to have_content "aucun service"
    end
  end

  describe "quand on a activé les services sur le territoire, mais qu'on ne les a pas encore ajouté aux agents" do
    let!(:service) { create(:service, territories: [organisation.territory]) }
    let!(:other_agent) { create(:agent, service: nil, basic_role_in_organisations: [organisation]) }

    it "affiche les infos de service" do
      visit admin_organisation_agents_path(organisation_id: organisation.id)
      expect(page).to have_content "Service"

      visit new_admin_organisation_agent_path(organisation_id: organisation.id)
      expect(page).to have_content "Service"

      visit edit_admin_organisation_agent_path(organisation_id: organisation.id, id: other_agent.id)
      expect(page).to have_content "aucun service"
    end
  end

  describe "quand on a désactivé les services sur le territoire, mais qu'on ne les a pas encore supprimé des agents" do
    let!(:service) { create(:service, territories: []) }
    let!(:other_agent) { create(:agent, :with_service, basic_role_in_organisations: [organisation]) }

    it "affiche les infos de service, sauf sur le formulaire de création" do
      visit admin_organisation_agents_path(organisation_id: organisation.id)
      expect(page).to have_content "Service"

      visit new_admin_organisation_agent_path(organisation_id: organisation.id)
      expect(page).not_to have_content "Service"

      visit edit_admin_organisation_agent_path(organisation_id: organisation.id, id: other_agent.id)
      expect(page).to have_content "appartient au service"
    end
  end
end

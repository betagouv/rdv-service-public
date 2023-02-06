# frozen_string_literal: true

describe "Admin can configure the organisation" do
  let(:territory) { create(:territory) }
  let(:organisation) { create(:organisation, territory: territory) }

  let(:agent) { create(:agent, basic_role_in_organisations: [organisation], role_in_territories: [territory]) }
  let!(:agent_access_right) { create(:agent_territorial_access_right, allow_to_manage_access_rights: true, territory: territory, agent: agent) }
  let(:other_agent) { create(:agent, basic_role_in_organisations: [organisation], role_in_territories: []) }
  let!(:other_agent_access_right) { create(:agent_territorial_access_right, allow_to_manage_access_rights: false, territory: territory, agent: other_agent) }

  before do
    login_as(agent, scope: :agent)
    visit edit_admin_territory_agent_path(territory, other_agent)
  end

  it "can give territorial admin access to other agent" do
    check("Administrateur du territoire")
    within(".agent-territorial") do
      expect { click_on("Enregistrer") }.to change { other_agent.reload.territorial_admin_in?(territory) }.to(true)
    end
  end
end

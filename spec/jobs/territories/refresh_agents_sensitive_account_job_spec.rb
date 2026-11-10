RSpec.describe Territories::RefreshAgentsSensitiveAccountJob, type: :job do
  let(:territory) { create(:territory, force_2fa_for_agents: true) }
  let(:organisation) { create(:organisation, territory:) }

  it "recalcule les agents des organisations de l'espace et ses admins" do
    basic_agent = create(:agent, basic_role_in_organisations: [organisation], sensitive_account: false)
    territory_admin = create(:agent, role_in_territories: [territory], sensitive_account: false)

    described_class.perform_now(territory)

    expect(basic_agent.reload.sensitive_account).to be true
    expect(territory_admin.reload.sensitive_account).to be true
  end

  it "ne modifie pas les agents d'autres espaces" do
    other_agent = create(:agent, basic_role_in_organisations: [create(:organisation)], sensitive_account: true)

    described_class.perform_now(territory)

    expect(other_agent.reload.sensitive_account).to be true
  end
end

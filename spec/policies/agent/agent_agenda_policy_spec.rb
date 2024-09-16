RSpec.describe Agent::AgentAgendaPolicy, type: :policy do
  subject { described_class }

  let(:pundit_context) { AgentContext.new(agent) }
  let!(:organisation) { create(:organisation) }

  describe "#show?" do
    context "regular agent, own agenda" do
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
      let(:agenda) { AgentAgenda.new(agent: agent, organisation: organisation) }

      permissions(:show?) { it { is_expected.to permit(pundit_context, agenda) } }
    end

    context "regular agent, other agent's agenda BUT same service" do
      let!(:service) { create(:service) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
      let!(:other_agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
      let(:agenda) { AgentAgenda.new(agent: other_agent, organisation: organisation) }

      permissions(:show?) { it { is_expected.to permit(pundit_context, agenda) } }
    end

    context "regular agent, other agent's absence, different service" do
      let!(:service) { create(:service) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
      let!(:other_agent) { create(:agent, basic_role_in_organisations: [organisation], service: create(:service)) }
      let(:agenda) { AgentAgenda.new(agent: other_agent, organisation: organisation) }

      permissions(:show?) { it { is_expected.not_to permit(pundit_context, agenda) } }
    end

    context "regular agent, other agent does not belong to current organisation" do
      let!(:service) { create(:service) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
      let!(:organisation2) { create(:organisation) }
      let!(:other_agent) { create(:agent, basic_role_in_organisations: [organisation2], service: create(:service)) }
      let(:agenda) { AgentAgenda.new(agent: other_agent, organisation: organisation) }

      permissions(:show?) { it { is_expected.not_to permit(pundit_context, agenda) } }
    end

    context "admin agent, other agent's absence, different service" do
      let!(:service) { create(:service) }
      let!(:agent) { create(:agent, admin_role_in_organisations: [organisation], service: service) }
      let!(:other_agent) { create(:agent, basic_role_in_organisations: [organisation], service: create(:service)) }
      let(:agenda) { AgentAgenda.new(agent: other_agent, organisation: organisation) }

      permissions(:show?) { it { is_expected.to permit(pundit_context, agenda) } }
    end
  end
end

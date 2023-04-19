# frozen_string_literal: true

describe Agent::AbsencePolicy, type: :policy do
  subject { described_class }

  let(:pundit_context) { AgentContext.new(agent) }
  let!(:organisation) { create(:organisation) }

  describe "#update?" do
    context "regular agent, own absence" do
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
      let!(:absence) { create(:absence, agent: agent) }

      permissions(:update?) { it { is_expected.to permit(pundit_context, absence) } }
    end

    context "regular agent, other agent's absence BUT same service" do
      let!(:service) { create(:service) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
      let!(:other_agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
      let!(:absence) { create(:absence, agent: other_agent) }

      permissions(:update?) { it { is_expected.to permit(pundit_context, absence) } }
    end

    context "regular agent, other agent's absence, different service" do
      let!(:service) { create(:service) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
      let!(:other_agent) { create(:agent, basic_role_in_organisations: [organisation], service: create(:service)) }
      let!(:absence) { create(:absence, agent: other_agent) }

      permissions(:update?) { it { is_expected.not_to permit(pundit_context, absence) } }
    end

    context "admin agent, other agent's absence, different service" do
      let!(:service) { create(:service) }
      let!(:agent) { create(:agent, admin_role_in_organisations: [organisation], service: service) }
      let!(:other_agent) { create(:agent, basic_role_in_organisations: [organisation], service: create(:service)) }
      let!(:absence) { create(:absence, agent: other_agent) }

      permissions(:update?) { it { is_expected.to permit(pundit_context, absence) } }
    end
  end
end

describe Agent::AbsencePolicy::Scope, type: :policy do
  describe "#resolve?" do
    subject(:scope) { described_class.new(AgentContext.new(current_agent), Absence).resolve }

    context "when I am not in secretariat service" do
      let!(:organisation_where_im_basic) { create(:organisation) }
      let!(:organisation_where_im_admin) { create(:organisation) }
      let!(:organisation_where_im_not) { create(:organisation) }

      let!(:my_service) { create(:service) }
      let!(:other_service) { create(:service) }

      let!(:current_agent) do
        create(
          :agent,
          basic_role_in_organisations: [organisation_where_im_basic],
          admin_role_in_organisations: [organisation_where_im_admin],
          service: my_service
        )
      end

      let!(:my_absence) { create(:absence, agent: current_agent) }
      let!(:agent_in_basic_org_same_service) { create(:agent, basic_role_in_organisations: [organisation_where_im_basic], service: my_service) }
      let!(:agent_in_basic_org_other_service) { create(:agent, basic_role_in_organisations: [organisation_where_im_basic], service: other_service) }
      let!(:agent_in_admin_org_same_service) { create(:agent, basic_role_in_organisations: [organisation_where_im_admin], service: my_service) }
      let!(:agent_in_admin_org_other_service) { create(:agent, basic_role_in_organisations: [organisation_where_im_admin], service: other_service) }

      let!(:absence_in_basic_org_same_service) { create(:absence, agent: agent_in_basic_org_same_service) }
      let!(:absence_in_basic_org_other_service) { create(:absence, agent: agent_in_basic_org_other_service) }
      let!(:absence_in_admin_org_same_service) { create(:absence, agent: agent_in_admin_org_same_service) }
      let!(:absence_in_admin_org_other_service) { create(:absence, agent: agent_in_admin_org_other_service) }

      it do
        expect(scope).to include(my_absence)
        expect(scope).to include(absence_in_basic_org_same_service)
        expect(scope).not_to include(absence_in_basic_org_other_service)
        expect(scope).to include(absence_in_admin_org_same_service)
        expect(scope).to include(absence_in_admin_org_other_service)
      end
    end
  end
end

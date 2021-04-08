describe Agent::AbsencePolicy, type: :policy do
  subject { described_class }

  let(:pundit_context) { AgentContext.new(agent) }
  let!(:organisation) { create(:organisation) }

  describe "#show?" do
    context "regular agent, own absence" do
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
      let!(:absence) { create(:absence, agent: agent, organisation: organisation) }

      permissions(:show?) { it { is_expected.to permit(pundit_context, absence) } }
    end

    context "regular agent, other agent's absence BUT same service" do
      let!(:service) { create(:service) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
      let!(:other_agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
      let!(:absence) { create(:absence, agent: other_agent, organisation: organisation) }

      permissions(:show?) { it { is_expected.to permit(pundit_context, absence) } }
    end

    context "regular agent, other agent's absence, different service" do
      let!(:service) { create(:service) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
      let!(:other_agent) { create(:agent, basic_role_in_organisations: [organisation], service: create(:service)) }
      let!(:absence) { create(:absence, agent: other_agent, organisation: organisation) }

      permissions(:show?) { it { is_expected.not_to permit(pundit_context, absence) } }
    end

    context "admin agent, other agent's absence, different service" do
      let!(:service) { create(:service) }
      let!(:agent) { create(:agent, admin_role_in_organisations: [organisation], service: service) }
      let!(:other_agent) { create(:agent, basic_role_in_organisations: [organisation], service: create(:service)) }
      let!(:absence) { create(:absence, agent: other_agent, organisation: organisation) }

      permissions(:show?) { it { is_expected.to permit(pundit_context, absence) } }
    end
  end
end

describe Agent::AbsencePolicy::Scope, type: :policy do
  describe "#resolve?" do
    subject { described_class.new(AgentContext.new(agent), Absence).resolve }

    context "misc state" do
      let!(:organisations) { create_list(:organisation, 4) }
      let!(:services) { create_list(:service, 2) }
      let!(:agent) do
        create(
          :agent,
          basic_role_in_organisations: [organisations[0], organisations[1]],
          admin_role_in_organisations: [organisations[2]],
          service: services[0]
        )
      end
      let!(:absence1) { create(:absence, agent: agent, organisation: organisations[0]) }
      let!(:absence2) { create(:absence, agent: agent, organisation: organisations[1]) }
      let!(:absence_same_service) { create(:absence, agent: create(:agent, service: services[0]), organisation: organisations[1]) }
      let!(:absence_other_service) { create(:absence, agent: create(:agent, service: services[1]), organisation: organisations[1]) }
      let!(:absence_other_service_but_admin) { create(:absence, agent: create(:agent, service: services[1]), organisation: organisations[2]) }
      let!(:absence_other_orga) { create(:absence, agent: create(:agent, service: services[0]), organisation: organisations[3]) }

      it { is_expected.to include(absence1) }
      it { is_expected.to include(absence2) }
      it { is_expected.to include(absence_same_service) }
      it { is_expected.not_to include(absence_other_service) }
      it { is_expected.to include(absence_other_service_but_admin) }
      it { is_expected.not_to include(absence_other_orga) }
    end
  end
end

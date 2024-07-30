RSpec.describe Agent::AgentPolicy, type: :policy do
  subject { described_class }

  let(:pundit_context) { AgentContext.new(agent) }
  let!(:organisation) { create(:organisation) }
  let!(:organisation2) { create(:organisation) }

  %i[show? new? create? edit? update? invite? rdvs? reinvite? versions?].each do |action|
    describe "##{action}" do
      context "regular agent, self" do
        let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

        permissions(action) { it { is_expected.to permit(pundit_context, agent) } }
      end

      context "regular agent, other agent same orga" do
        let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
        let!(:other_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

        permissions(action) { it { is_expected.not_to permit(pundit_context, other_agent) } }
      end

      context "admin agent, other agent same orga" do
        let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
        let!(:other_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

        permissions(action) { it { is_expected.to permit(pundit_context, other_agent.reload) } }
      end

      context "admin agent, other agent different orga" do
        let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
        let!(:other_agent) { create(:agent, basic_role_in_organisations: [create(:organisation)]) }

        permissions(action) { it { is_expected.not_to permit(pundit_context, other_agent) } }
      end

      context "regular agent, other agent is admin in same orga" do
        let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
        let!(:other_agent) { create(:agent, admin_role_in_organisations: [create(:organisation)]) }

        permissions(action) { it { is_expected.not_to permit(pundit_context, other_agent) } }
      end
    end
  end

  describe "#destroy?" do
    context "regular agent, other agent same org" do
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
      let!(:other_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      permissions(:destroy?) { it { is_expected.not_to permit(pundit_context, other_agent) } }
    end

    context "admin agent, other agent same org" do
      let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
      let!(:other_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      permissions(:destroy?) { it { is_expected.to permit(pundit_context, other_agent.reload) } }
    end

    context "admin agent, self" do
      let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

      permissions(:destroy?) { it { is_expected.not_to permit(pundit_context, agent) } }
    end
  end
end

RSpec.describe Agent::AgentPolicy::Scope, type: :policy do
  describe "#resolve?" do
    subject { described_class.new(AgentContext.new(agent), Agent).resolve }

    context "regular agent" do
      let!(:services) { create_list(:service, 2) }
      let!(:organisations) { create_list(:organisation, 2) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisations[0]], service: services[0]) }
      let!(:other_agent_same_service) { create(:agent, basic_role_in_organisations: [organisations[0]], service: services[0]) }
      let!(:other_agent_different_orga) { create(:agent, basic_role_in_organisations: [organisations[1]], service: services[0]) }
      let!(:other_agent_different_service) { create(:agent, basic_role_in_organisations: [organisations[0]], service: services[1]) }

      it do
        expect(subject).to include(agent)
        expect(subject).to include(other_agent_same_service)
        expect(subject).not_to include(other_agent_different_orga)
        expect(subject).not_to include(other_agent_different_service)
      end
    end

    context "agent is in secrétariat" do
      let!(:service_secretariat) { create(:service, :secretariat) }
      let!(:other_service) { create :service }
      let!(:services) { create_list(:service, 2) }
      let!(:organisations) { create_list(:organisation, 2) }
      let!(:agent) { create(:agent, basic_role_in_organisations: organisations, service: service_secretariat) }
      let!(:other_agent_same_orgas) { create(:agent, basic_role_in_organisations: organisations, service: other_service) }

      it { is_expected.to match_array([agent, other_agent_same_orgas]) }

      context "when agent is also territory admin" do
        let!(:territory) { create(:territory) }
        let!(:organisations) { create_list(:organisation, 2, territory: territory) }
        let!(:other_organisation_in_territory) { create(:organisation, territory: territory) }
        let!(:agent_in_other_org_in_territory) { create(:agent, organisations: [other_organisation_in_territory]) }

        before { agent.territories << territory }

        it { is_expected.to match_array([agent, other_agent_same_orgas, agent_in_other_org_in_territory]) }
      end
    end

    context "admin agent, misc state" do
      let!(:organisations) { create_list(:organisation, 4) }
      let!(:agent) do
        create(
          :agent,
          basic_role_in_organisations: [organisations[0]],
          admin_role_in_organisations: [organisations[1], organisations[2]]
        )
      end
      let!(:other_agent1) { create(:agent, basic_role_in_organisations: [organisations[0]]) }
      let!(:other_agent2) { create(:agent, basic_role_in_organisations: [organisations[1]]) }
      let!(:other_agent3) { create(:agent, basic_role_in_organisations: [organisations[2]]) }
      let!(:other_agent4) { create(:agent, basic_role_in_organisations: [organisations[3]]) }
      let!(:other_agent5) { create(:agent, admin_role_in_organisations: [organisations[2]]) }

      it do
        expect(subject).not_to include(other_agent1)
        expect(subject).to include(other_agent2)
        expect(subject).to include(other_agent3)
        expect(subject).not_to include(other_agent4)
        expect(subject).to include(other_agent5)
      end
    end

    context "agent has territorial role" do
      let!(:territories) { create_list(:territory, 2) }
      let!(:same_territory_organisations) { create_list(:organisation, 3, territory: territories[0]) }
      let!(:other_territory_organisations) { create_list(:organisation, 3, territory: territories[1]) }
      let!(:agent) do
        create(
          :agent,
          basic_role_in_organisations: [same_territory_organisations[0], other_territory_organisations[0]],
          admin_role_in_organisations: [same_territory_organisations[1], other_territory_organisations[1]],
          role_in_territories: [territories[0]]
        )
      end
      let!(:other_agent_same_territory1) { create(:agent, basic_role_in_organisations: [same_territory_organisations[0]]) }
      let!(:other_agent_same_territory2) { create(:agent, basic_role_in_organisations: [same_territory_organisations[1]]) }
      let!(:other_agent_same_territory3) { create(:agent, basic_role_in_organisations: [same_territory_organisations[2]]) }
      let!(:other_agent_different_territory1) { create(:agent, basic_role_in_organisations: [other_territory_organisations[0]]) }
      let!(:other_agent_different_territory2) { create(:agent, basic_role_in_organisations: [other_territory_organisations[1]]) }
      let!(:other_agent_different_territory3) { create(:agent, basic_role_in_organisations: [other_territory_organisations[2]]) }

      it do
        expect(subject).to include(other_agent_same_territory1)
        expect(subject).to include(other_agent_same_territory2)
        expect(subject).to include(other_agent_same_territory3)
        expect(subject).not_to include(other_agent_different_territory1)
        expect(subject).to include(other_agent_different_territory2)
        expect(subject).not_to include(other_agent_different_territory3)
      end
    end
  end
end

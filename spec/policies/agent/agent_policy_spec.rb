RSpec.describe Agent::AgentPolicy, type: :policy do
  subject { described_class }

  let(:pundit_context) { AgentContext.new(agent) }
  let!(:organisation) { create(:organisation) }
  let!(:organisation2) { create(:organisation) }

  %i[show? edit? update? reinvite? versions?].each do |action|
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

  describe "#create?" do
    it "n'autorise pas un agent admin d'une orga à créer un nouvel agent dans cette orga ET une autre" do
      current_agent = create(:agent, admin_role_in_organisations: [organisation])
      agent_cible = Agent.new(organisations: [organisation, organisation2])
      expect(described_class.new(AgentContext.new(current_agent), agent_cible).create?).to be false
      expect(described_class.new(AgentContext.new(current_agent), agent_cible).new?).to be false
    end

    it "n'autorise pas un agent à créer un nouvel agent sans aucune organisation" do
      current_agent = create(:agent, admin_role_in_organisations: [organisation])
      agent_cible = Agent.new(organisations: [])
      expect(described_class.new(AgentContext.new(current_agent), agent_cible).create?).to be false
      expect(described_class.new(AgentContext.new(current_agent), agent_cible).new?).to be false
    end

    it "n'autorise pas un agent non admin à créer un nouvel agent dans son organisation" do
      current_agent = create(:agent, basic_role_in_organisations: [organisation])
      agent_cible = Agent.new(organisations: [organisation])
      expect(described_class.new(AgentContext.new(current_agent), agent_cible).create?).to be false
      expect(described_class.new(AgentContext.new(current_agent), agent_cible).new?).to be false
    end

    it "autorise un agent admin à créer un nouvel agent dans son organisation" do
      current_agent = create(:agent, admin_role_in_organisations: [organisation])
      agent_cible = Agent.new(organisations: [organisation])
      expect(described_class.new(AgentContext.new(current_agent), agent_cible).create?).to be true
      expect(described_class.new(AgentContext.new(current_agent), agent_cible).new?).to be true
    end

    it "n'autorise pas un agent admin à créer un nouvel agent dans une autre organisation que la sienne" do
      current_agent = create(:agent, admin_role_in_organisations: [organisation])
      agent_cible = Agent.new(organisations: [organisation2])
      expect(described_class.new(AgentContext.new(current_agent), agent_cible).create?).to be false
      expect(described_class.new(AgentContext.new(current_agent), agent_cible).new?).to be false
    end

    it "autorise un agent admin de 2 organisations à créer un nouvel agent dans une seule d'entre elles" do
      current_agent = create(:agent, admin_role_in_organisations: [organisation, organisation2])
      agent_cible = Agent.new(organisations: [organisation])
      expect(described_class.new(AgentContext.new(current_agent), agent_cible).create?).to be true
      expect(described_class.new(AgentContext.new(current_agent), agent_cible).new?).to be true
    end

    it "autorise un agent admin de 3 organisations à créer un nouvel agent dans 2 d'entre elles" do
      organisation3 = create(:organisation)
      current_agent = create(:agent, admin_role_in_organisations: [organisation, organisation2, organisation3])
      agent_cible = Agent.new(organisations: [organisation, organisation2])
      expect(described_class.new(AgentContext.new(current_agent), agent_cible).create?).to be true
      expect(described_class.new(AgentContext.new(current_agent), agent_cible).new?).to be true
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

    context "agent basique avec un confrère sans service" do
      let!(:organisation) { create(:organisation) }
      let!(:agent) { create(:agent, :with_service, basic_role_in_organisations: [organisation]) }
      let!(:confrere_sans_service) { create(:agent, basic_role_in_organisations: [organisation]) }
      let!(:autre_agent_service_different) { create(:agent, :with_service, basic_role_in_organisations: [organisation]) }

      it { is_expected.to contain_exactly(agent, confrere_sans_service) }
    end

    context "agent basique sans service" do
      let!(:organisation) { create(:organisation) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
      let!(:autre_agent_sans_service) { create(:agent, basic_role_in_organisations: [organisation]) }
      let!(:autre_agent_avec_service) { create(:agent, :with_service, basic_role_in_organisations: [organisation]) }

      it { is_expected.to contain_exactly(agent, autre_agent_sans_service) }
    end

    context "agent basique avec un administrateur d'un autre service dans la même organisation" do
      let!(:organisation) { create(:organisation) }
      let!(:agent) { create(:agent, :with_service, basic_role_in_organisations: [organisation]) }
      let!(:administrateur_service_different) { create(:agent, :with_service, admin_role_in_organisations: [organisation]) }

      it { is_expected.to contain_exactly(agent, administrateur_service_different) }
    end

    context "when agent is agent d'accueil" do
      let!(:other_service) { create :service }
      let!(:organisations) { create_list(:organisation, 2) }
      let!(:agent) { create(:agent, agent_accueil_role_in_organisations: organisations) }
      let!(:other_agent_same_orgas) { create(:agent, basic_role_in_organisations: organisations, service: other_service) }

      it { is_expected.to contain_exactly(agent, other_agent_same_orgas) }

      context "when agent d'accueil is also territory admin" do
        let!(:territory) { create(:territory) }
        let!(:organisations) { create_list(:organisation, 2, territory: territory) }
        let!(:other_organisation_in_territory) { create(:organisation, territory: territory) }
        let!(:agent_in_other_org_in_territory) { create(:agent, organisations: [other_organisation_in_territory]) }

        before { agent.territories << territory }

        it { is_expected.to contain_exactly(agent, other_agent_same_orgas, agent_in_other_org_in_territory) }
      end
    end

    context "admin agent, misc state" do
      let!(:organisations) { create_list(:organisation, 4) }
      let!(:agent) do
        create(
          :agent, :with_service,
          basic_role_in_organisations: [organisations[0]],
          admin_role_in_organisations: [organisations[1], organisations[2]]
        )
      end
      let!(:other_agent1) { create(:agent, :with_service, basic_role_in_organisations: [organisations[0]]) }
      let!(:other_agent2) { create(:agent, :with_service, basic_role_in_organisations: [organisations[1]]) }
      let!(:other_agent3) { create(:agent, :with_service, basic_role_in_organisations: [organisations[2]]) }
      let!(:other_agent4) { create(:agent, :with_service, basic_role_in_organisations: [organisations[3]]) }
      let!(:other_agent5) { create(:agent, :with_service, admin_role_in_organisations: [organisations[2]]) }

      specify do
        expect(subject).to contain_exactly(agent, other_agent2, other_agent3, other_agent5)
      end
    end

    context "agent has territorial role" do
      let!(:territories) { create_list(:territory, 2) }
      let!(:same_territory_organisations) { create_list(:organisation, 3, territory: territories[0]) }
      let!(:other_territory_organisations) { create_list(:organisation, 3, territory: territories[1]) }
      let!(:agent) do
        create(
          :agent, :with_service,
          basic_role_in_organisations: [same_territory_organisations[0], other_territory_organisations[0]],
          admin_role_in_organisations: [same_territory_organisations[1], other_territory_organisations[1]],
          role_in_territories: [territories[0]]
        )
      end
      let!(:other_agent_same_territory1) { create(:agent, basic_role_in_organisations: [same_territory_organisations[0]]) }
      let!(:other_agent_same_territory2) { create(:agent, basic_role_in_organisations: [same_territory_organisations[1]]) }
      let!(:other_agent_same_territory3) { create(:agent, basic_role_in_organisations: [same_territory_organisations[2]]) }
      let!(:other_agent_different_territory1) { create(:agent, :with_service, basic_role_in_organisations: [other_territory_organisations[0]]) }
      let!(:other_agent_different_territory2) { create(:agent, basic_role_in_organisations: [other_territory_organisations[1]]) }
      let!(:other_agent_different_territory3) { create(:agent, basic_role_in_organisations: [other_territory_organisations[2]]) }

      it do
        expect(subject).to contain_exactly(
          agent,
          other_agent_same_territory1,
          other_agent_same_territory2,
          other_agent_same_territory3,
          other_agent_different_territory2
        )
      end
    end
  end
end

describe Agent::RdvPolicy, type: :policy do
  subject { described_class }

  shared_examples "permit actions" do |*actions|
    actions.each do |action|
      permissions action do
        it { is_expected.to permit(pundit_context, rdv) }
      end
    end
  end

  shared_examples "not permit actions" do |*actions|
    actions.each do |action|
      permissions action do
        it { is_expected.not_to permit(pundit_context, rdv) }
      end
    end
  end

  shared_examples "included in scope" do
    it "is included in scope" do
      expect(Agent::RdvPolicy::Scope.new(pundit_context, Rdv).resolve).to include(rdv)
    end
  end

  shared_examples "not included in scope" do
    it "is not included in scope" do
      expect(Agent::RdvPolicy::Scope.new(pundit_context, Rdv).resolve).not_to include(rdv)
    end
  end

  context "existing RDV from same agent" do
    let(:organisation) { create(:organisation) }
    let(:service) { create(:service) }
    let(:agent) { create(:agent, basic_role_in_organisations: [organisation], services: [service]) }
    let(:motif) { create(:motif, organisation: organisation, service: service) }
    let(:rdv) { create(:rdv, organisation: organisation, agents: [agent], motif: motif) }
    let(:pundit_context) { AgentContext.new(agent, organisation) }

    it_behaves_like "permit actions", :show?, :edit?, :update?, :destroy?
    it_behaves_like "included in scope"
  end

  context "existing RDV from other agent from other service" do
    let(:organisation) { create(:organisation) }
    let(:service_agent) { build(:service) }
    let(:service_rdv) { build(:service) }
    let(:motif) { create(:motif, organisation: organisation, service: service_rdv) }
    let(:rdv) { create(:rdv, motif: motif, organisation: organisation) }
    let(:agent) { create(:agent, basic_role_in_organisations: [organisation], services: [service_agent]) }
    let(:pundit_context) { AgentContext.new(agent, organisation) }

    it_behaves_like "not permit actions", :show?, :edit?, :update?, :destroy?
    it_behaves_like "not included in scope"

    context "for secretariat" do
      let(:service_agent) { build(:service, :secretariat) }

      it_behaves_like "permit actions", :show?, :edit?, :update?, :destroy?
      it_behaves_like "included in scope"
    end

    context "for admin" do
      let(:agent) { create(:agent, admin_role_in_organisations: [organisation], services: [service_agent]) }

      it_behaves_like "permit actions", :show?, :edit?, :update?, :destroy?
      it_behaves_like "included in scope"
    end
  end

  xcontext "existing RDV from other agent from same service" do
    let(:organisation) { create(:organisation) }
    let(:service) { create(:service) }
    let(:agents) { create_list(:agent, 2, organisations: [organisation], services: [service]) }
    let(:motif) { create(:motif, organisation: organisation, service: service) }
    let(:rdv) { create(:rdv, agents: [agents[0]], motif: motif, organisation: organisation) }
    let(:pundit_context) { AgentContext.new(agents[1], organisation) }

    it_behaves_like "permit actions", :show?, :edit?, :update?, :destroy?
    it_behaves_like "included in scope"
  end

  xcontext "existing RDV from other orga from same service" do
    let(:organisation1) { create(:organisation) }
    let(:organisation2) { create(:organisation) }
    let(:service) { create(:service) }
    let(:agent1) { create(:agent, basic_role_in_organisations: [organisation1], services: [service]) }
    let(:agent2) { create(:agent, basic_role_in_organisations: [organisation2], services: [service]) }
    let(:motif1) { create(:motif, organisation: organisation1, service: service) }
    let(:rdv) { create(:rdv, agents: [agent1], motif: motif1, organisation: organisation1) }
    let(:pundit_context) { AgentContext.new(agent2, organisation2) }

    it_behaves_like "not permit actions", :show?, :edit?, :update?, :destroy?
    it_behaves_like "not included in scope"

    context "for secretariat" do
      let(:agent2) { create(:agent, basic_role_in_organisations: [organisation2], services: [create(:service, :secretariat)]) }

      it_behaves_like "not permit actions", :show?, :edit?, :update?, :destroy?
      it_behaves_like "not included in scope"
    end

    context "for admin" do
      let(:agent2) { create(:agent, admin_role_in_organisations: [organisation2], services: [service]) }

      it_behaves_like "not permit actions", :show?, :edit?, :update?, :destroy?
      it_behaves_like "not included in scope"
    end
  end

  # TODO: write cases for :new? and create? which
end

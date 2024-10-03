RSpec.describe Agent::RdvPolicy, type: :policy do
  subject { described_class }

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
    let(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
    let(:motif) { create(:motif, organisation: organisation, service: service) }
    let(:rdv) { create(:rdv, organisation: organisation, agents: [agent], motif: motif) }
    let(:pundit_context) { agent }

    it_behaves_like "permit actions", :rdv, :show?, :edit?, :update?
    it_behaves_like "not permit actions", :rdv, :destroy?
    it_behaves_like "included in scope"
  end

  context "existing RDV from other agent from other service" do
    let(:organisation) { create(:organisation) }
    let(:service_agent) { build(:service) }
    let(:service_rdv) { build(:service) }
    let(:motif) { create(:motif, organisation: organisation, service: service_rdv) }
    let(:rdv) { create(:rdv, motif: motif, organisation: organisation) }
    let(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service_agent) }
    let(:pundit_context) { agent }

    it_behaves_like "not permit actions", :rdv, :show?, :edit?, :update?, :destroy?
    it_behaves_like "not included in scope"

    context "for secretariat" do
      let(:service_agent) { build(:service, :secretariat) }

      it_behaves_like "permit actions", :rdv, :show?, :edit?, :update?
      it_behaves_like "not permit actions", :rdv, :destroy?
      it_behaves_like "included in scope"
    end

    context "for admin" do
      let(:agent) { create(:agent, admin_role_in_organisations: [organisation], service: service_agent) }

      it_behaves_like "permit actions", :rdv, :show?, :edit?, :update?, :destroy?
      it_behaves_like "included in scope"
    end

    context "except if the rdv concerns the connected agent" do
      let(:rdv) { create(:rdv, motif: motif, organisation: organisation, agents: [agent]) }

      it_behaves_like "permit actions", :rdv, :show?, :edit?, :update?
      it_behaves_like "not permit actions", :rdv, :destroy?
      it_behaves_like "included in scope"
    end
  end

  context "existing RDV from other agent from same service" do
    let(:organisation) { create(:organisation) }
    let(:service) { create(:service) }
    let(:agents) { create_list(:agent, 2, organisations: [organisation], service: service) }
    let(:motif) { create(:motif, organisation: organisation, service: service) }
    let(:rdv) { create(:rdv, agents: [agents[0]], motif: motif, organisation: organisation) }
    let(:pundit_context) { agents[1] }

    it_behaves_like "permit actions", :rdv, :show?, :edit?, :update?
    it_behaves_like "not permit actions", :rdv, :destroy?
    it_behaves_like "included in scope"
  end

  context "existing RDV from other orga from same service" do
    let(:organisation1) { create(:organisation) }
    let(:organisation2) { create(:organisation) }
    let(:service) { create(:service) }
    let(:agent1) { create(:agent, basic_role_in_organisations: [organisation1], service: service) }
    let(:agent2) { create(:agent, basic_role_in_organisations: [organisation2], service: service) }
    let(:motif1) { create(:motif, organisation: organisation1, service: service) }
    let(:rdv) { create(:rdv, agents: [agent1], motif: motif1, organisation: organisation1) }
    let(:pundit_context) { agent2 }

    it_behaves_like "not permit actions", :rdv, :show?, :edit?, :update?, :destroy?
    it_behaves_like "not included in scope"

    context "for secretariat" do
      let(:agent2) { create(:agent, basic_role_in_organisations: [organisation2], service: create(:service, :secretariat)) }

      it_behaves_like "not permit actions", :rdv, :show?, :edit?, :update?, :destroy?
      it_behaves_like "not included in scope"
    end

    context "for admin" do
      let(:agent2) { create(:agent, admin_role_in_organisations: [organisation2], service: service) }

      it_behaves_like "not permit actions", :rdv, :show?, :edit?, :update?, :destroy?
      it_behaves_like "not included in scope"
    end
  end

  # TODO: write cases for :new? and create? which
end

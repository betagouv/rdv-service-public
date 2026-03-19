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
    let(:pundit_context) { AgentOrganisationContext.new(agent, organisation) }

    it_behaves_like "permit actions", :rdv, :show?, :download_participants?, :edit?, :update?
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
    let(:pundit_context) { AgentOrganisationContext.new(agent, organisation) }

    it_behaves_like "not permit actions", :rdv, :show?, :download_participants?, :edit?, :update?, :destroy?
    it_behaves_like "not included in scope"

    context "for secretariat" do
      let(:service_agent) { build(:service, :secretariat) }

      it_behaves_like "permit actions", :rdv, :show?, :download_participants?, :edit?, :update?
      it_behaves_like "not permit actions", :rdv, :destroy?
      it_behaves_like "included in scope"
    end

    context "for admin" do
      let(:agent) { create(:agent, admin_role_in_organisations: [organisation], service: service_agent) }

      it_behaves_like "permit actions", :rdv, :show?, :download_participants?, :edit?, :update?, :destroy?
      it_behaves_like "included in scope"
    end

    context "except if the rdv concerns the connected agent" do
      let(:rdv) { create(:rdv, motif: motif, organisation: organisation, agents: [agent]) }

      it_behaves_like "permit actions", :rdv, :show?, :download_participants?, :edit?, :update?
      it_behaves_like "not permit actions", :rdv, :destroy?
      it_behaves_like "included in scope"
    end
  end

  context "existing RDV from other agent on a motif without service" do
    let(:organisation) { create(:organisation) }
    let(:agents) { create_list(:agent, 2, organisations: [organisation]) }
    let(:motif) { create(:motif, organisation: organisation, service: nil) }
    let(:rdv) { create(:rdv, agents: [agents[0]], motif: motif, organisation: organisation) }
    let(:pundit_context) { AgentOrganisationContext.new(agents[1], organisation) }

    it_behaves_like "permit actions", :rdv, :show?, :download_participants?, :edit?, :update?
    it_behaves_like "not permit actions", :rdv, :destroy?
    it_behaves_like "included in scope"
  end

  context "existing RDV from other agent from same service" do
    let(:organisation) { create(:organisation) }
    let(:service) { create(:service) }
    let(:agents) { create_list(:agent, 2, organisations: [organisation], service: service) }
    let(:motif) { create(:motif, organisation: organisation, service: service) }
    let(:rdv) { create(:rdv, agents: [agents[0]], motif: motif, organisation: organisation) }
    let(:pundit_context) { AgentOrganisationContext.new(agents[1], organisation) }

    it_behaves_like "permit actions", :rdv, :show?, :download_participants?, :edit?, :update?
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
    let(:pundit_context) { AgentOrganisationContext.new(agent2, organisation2) }

    it_behaves_like "not permit actions", :rdv, :show?, :download_participants?, :edit?, :update?, :destroy?
    it_behaves_like "not included in scope"

    context "for secretariat" do
      let(:agent2) { create(:agent, basic_role_in_organisations: [organisation2], service: create(:service, :secretariat)) }

      it_behaves_like "not permit actions", :rdv, :show?, :download_participants?, :edit?, :update?, :destroy?
      it_behaves_like "not included in scope"
    end

    context "for admin" do
      let(:agent2) { create(:agent, admin_role_in_organisations: [organisation2], service: service) }

      it_behaves_like "not permit actions", :rdv, :show?, :download_participants?, :edit?, :update?, :destroy?
      it_behaves_like "not included in scope"
    end
  end

  context "RDV existant pour l’agent courant et un autre agent auquel iel a accès" do
    let(:organisation) { create(:organisation) }
    let(:service) { create(:service) }
    let(:agent1) { create(:agent, basic_role_in_organisations: [organisation], service:) }
    let(:agent2) { create(:agent, basic_role_in_organisations: [organisation], service:) }
    let(:motif) { create(:motif, organisation:, service: service) }
    let!(:rdv) { create(:rdv, agents: [agent1, agent2], motif:, organisation:) }
    let(:pundit_context) { AgentOrganisationContext.new(agent1, organisation) }

    it_behaves_like "permit actions", :rdv, :update?, :status?
  end

  context "RDV existant pour l’agent courant et un autre agent auquel iel n’a pas accès (autre organisation)" do
    # NOTE: ce cas de deux agents partageant un RDV mais n’ayant pas d’accès l’un à l’autre est peu probable
    let(:organisation) { create(:organisation) }
    let(:service) { create(:service) }
    let(:agent1) { create(:agent, basic_role_in_organisations: [organisation], service:) }
    let(:agent2) { create(:agent, basic_role_in_organisations: [create(:organisation)], service:) }
    let(:motif) { create(:motif, organisation:, service: service) }
    let!(:rdv) { create(:rdv, agents: [agent1, agent2], motif:, organisation:) }
    let(:pundit_context) { AgentOrganisationContext.new(agent1, organisation) }

    it_behaves_like "not permit actions", :rdv, :update?, :status?
  end

  # Certains controllers ajoutent des usagers à un RDV à travers
  # `@rdv.participations.build(...)`, puis appellent cette policy.
  # Cette section teste ce cas de figure.
  context "adding users from outside the current agent's territory" do
    let(:organisation) { create(:organisation) }
    let(:service) { create(:service) }
    let(:agent) { create(:agent, admin_role_in_organisations: [organisation], service: service) }
    let(:motif) { create(:motif, organisation: organisation, service: service) }
    let(:rdv) { create(:rdv, organisation: organisation, agents: [agent], motif: motif) }
    let(:pundit_context) { AgentOrganisationContext.new(agent, organisation) }

    before do
      user_from_other_territory = create(:user)
      rdv.participations.build(user_id: user_from_other_territory.id, created_by: agent)
    end

    it_behaves_like "permit actions", :rdv, :show?, :download_participants?, :destroy?
    it_behaves_like "not permit actions", :rdv, :new?, :create?, :edit?, :update?
    it_behaves_like "included in scope"
  end

  context "any participating user is soft deleted" do
    let(:organisation) { create(:organisation) }
    let(:service) { create(:service) }
    let(:agent) { create(:agent, admin_role_in_organisations: [organisation], service: service) }
    let(:motif) { create(:motif, organisation: organisation, service: service) }

    let(:live_user)         { create(:user, deleted_at: 2.weeks.ago) }
    let(:soft_deleted_user) { create(:user, deleted_at: 2.weeks.ago) }

    let(:live_agent)          { create(:agent, admin_role_in_organisations: [organisation], service: service, deleted_at: 2.weeks.ago) }
    let(:soft_deleted_agent)  { create(:agent, admin_role_in_organisations: [organisation], service: service, deleted_at: nil) }

    let(:rdv) { create(:rdv, organisation: organisation, agents: [live_agent, soft_deleted_agent], users: [live_user, soft_deleted_user], motif: motif) }
    let(:pundit_context) { AgentOrganisationContext.new(agent, organisation) }

    it_behaves_like "permit actions", :rdv, :new?, :create?, :show?, :download_participants?, :edit?, :update?, :destroy?
    it_behaves_like "not permit actions", :rdv
    it_behaves_like "included in scope"
  end

  context "the participating user belongs to no organisation but already has a RDV in my orgs" do
    let(:organisation) { create(:organisation) }
    let(:service) { create(:service) }
    let(:agent) { create(:agent, admin_role_in_organisations: [organisation], service: service) }
    let(:motif) { create(:motif, organisation: organisation, service: service) }

    let(:user) { create(:user) }
    let!(:rdv) { create(:rdv, organisation: organisation, agents: [agent], users: [user], motif: motif) }
    let(:pundit_context) { AgentOrganisationContext.new(agent, organisation) }

    before do
      # On s'assure que l'usager du RDV est sans orga
      user.user_profiles.destroy_all
    end

    it_behaves_like "permit actions", :rdv, :new?, :create?, :show?, :download_participants?, :edit?, :update?, :destroy?
    it_behaves_like "not permit actions", :rdv
    it_behaves_like "included in scope"
  end
end

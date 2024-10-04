RSpec.describe Agent::PlageOuverturePolicy, type: :policy do
  subject { described_class }

  let(:plage_ouverture) { create(:plage_ouverture) }
  let(:pundit_context) { AgentOrganisationContext.new(agent, plage_ouverture.organisation) }

  shared_examples "included in scope" do
    it "is included in scope" do
      expect(described_class::Scope.new(pundit_context, PlageOuverture).resolve).to include(plage_ouverture)
    end
  end

  shared_examples "not included in scope" do
    it "is not included in scope" do
      expect(described_class::Scope.new(pundit_context, PlageOuverture).resolve).not_to include(plage_ouverture)
    end
  end

  context "when the plage belongs to the given agent" do
    let(:agent) { plage_ouverture.agent }

    it_behaves_like "permit actions", :plage_ouverture, :new?, :show?, :versions?, :create?, :edit?, :update?, :destroy?
    it_behaves_like "included in scope"
  end

  context "when given agent is secrétaire" do
    context "when she does not belong to the plage's organisation" do
      let(:agent) { create(:agent, :secretaire, basic_role_in_organisations: [create(:organisation)]) }

      it_behaves_like "not permit actions", :plage_ouverture, :new?, :show?, :versions?, :create?, :edit?, :update?, :destroy?
      it_behaves_like "not included in scope"
    end

    context "when she belongs to the plage's organisation as basic member" do
      let(:agent) { create(:agent, :secretaire, basic_role_in_organisations: [plage_ouverture.organisation]) }

      it_behaves_like "permit actions", :plage_ouverture, :new?, :show?, :versions?, :create?, :edit?, :update?, :destroy?
      it_behaves_like "included in scope"
    end

    context "when she belongs to the plage's organisation as admin member" do
      let(:agent) { create(:agent, :secretaire, admin_role_in_organisations: [plage_ouverture.organisation]) }

      it_behaves_like "permit actions", :plage_ouverture, :new?, :show?, :versions?, :create?, :edit?, :update?, :destroy?
      it_behaves_like "included in scope"
    end
  end

  context "when given agent is not a secrétaire" do
    context "when she does not belong to the plage's organisation" do
      let(:agent) { create(:agent, basic_role_in_organisations: [create(:organisation)]) }

      it_behaves_like "not permit actions", :plage_ouverture, :new?, :show?, :versions?, :create?, :edit?, :update?, :destroy?
      it_behaves_like "not included in scope"
    end

    context "when she belongs to the plage's organisation as basic member" do
      let(:agent) { create(:agent, basic_role_in_organisations: [plage_ouverture.organisation]) }

      context "when she shares a service with the plage's agent" do
        before do
          service_in_common = build(:service)
          agent.services << service_in_common
          plage_ouverture.agent.services << service_in_common
          expect(agent.services.to_set.intersection(plage_ouverture.agent.services.to_set)).not_to be_empty # rubocop:disable RSpec/ExpectInHook
        end

        it_behaves_like "permit actions", :plage_ouverture, :new?, :show?, :versions?, :create?, :edit?, :update?, :destroy?
        it_behaves_like "included in scope"
      end

      context "when she shares no service with the plage's agent" do
        before do
          expect(agent.services.to_set.intersection(plage_ouverture.agent.services.to_set)).to be_empty # rubocop:disable RSpec/ExpectInHook
        end

        it_behaves_like "not permit actions", :plage_ouverture, :new?, :show?, :versions?, :create?, :edit?, :update?, :destroy?
        it_behaves_like "not included in scope"
      end
    end

    context "when she belongs to the plage's organisation as admin member" do
      let(:agent) { create(:agent, admin_role_in_organisations: [plage_ouverture.organisation]) }

      it_behaves_like "permit actions", :plage_ouverture, :new?, :show?, :versions?, :create?, :edit?, :update?, :destroy?
      it_behaves_like "included in scope"
    end
  end
end

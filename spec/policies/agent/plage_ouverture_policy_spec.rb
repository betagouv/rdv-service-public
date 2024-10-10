RSpec.describe Agent::PlageOuverturePolicy, type: :policy do
  let(:policy) { described_class.new(agent, plage_ouverture) }
  let(:policy_scope) { described_class::Scope.new(agent, PlageOuverture.all).resolve }

  let(:plage_ouverture) { create(:plage_ouverture) }

  context "when the plage belongs to the given agent" do
    let(:agent) { plage_ouverture.agent }

    it "allows read/write operations" do
      expect(policy.new?).to       be true
      expect(policy.create?).to    be true
      expect(policy.edit?).to      be true
      expect(policy.update?).to    be true
      expect(policy.destroy?).to   be true
      expect(policy.show?).to      be true
      expect(policy.versions?).to  be true

      expect(policy_scope).to include(plage_ouverture)
    end
  end

  context "when given agent is secrétaire" do
    context "when she does not belong to the plage's organisation" do
      let(:agent) { create(:agent, :secretaire, basic_role_in_organisations: [create(:organisation)]) }

      it "allows read/write operations" do
        expect(policy.new?).to       be false
        expect(policy.create?).to    be false
        expect(policy.edit?).to      be false
        expect(policy.update?).to    be false
        expect(policy.destroy?).to   be false
        expect(policy.show?).to      be false
        expect(policy.versions?).to  be false

        expect(policy_scope).not_to include(plage_ouverture)
      end
    end

    context "when she belongs to the plage's organisation as basic member" do
      let(:agent) { create(:agent, :secretaire, basic_role_in_organisations: [plage_ouverture.organisation]) }

      it "allows read/write operations" do
        expect(policy.new?).to       be true
        expect(policy.create?).to    be true
        expect(policy.edit?).to      be true
        expect(policy.update?).to    be true
        expect(policy.destroy?).to   be true
        expect(policy.show?).to      be true
        expect(policy.versions?).to  be true

        expect(policy_scope).to include(plage_ouverture)
      end
    end

    context "when she belongs to the plage's organisation as admin member" do
      let(:agent) { create(:agent, :secretaire, admin_role_in_organisations: [plage_ouverture.organisation]) }

      it "allows read/write operations" do
        expect(policy.new?).to       be true
        expect(policy.create?).to    be true
        expect(policy.edit?).to      be true
        expect(policy.update?).to    be true
        expect(policy.destroy?).to   be true
        expect(policy.show?).to      be true
        expect(policy.versions?).to  be true

        expect(policy_scope).to include(plage_ouverture)
      end
    end
  end

  context "when given agent is not a secrétaire" do
    context "when she does not belong to the plage's organisation" do
      let(:agent) { create(:agent, basic_role_in_organisations: [create(:organisation)]) }

      it "allows read/write operations" do
        expect(policy.new?).to       be false
        expect(policy.create?).to    be false
        expect(policy.edit?).to      be false
        expect(policy.update?).to    be false
        expect(policy.destroy?).to   be false
        expect(policy.show?).to      be false
        expect(policy.versions?).to  be false

        expect(policy_scope).not_to include(plage_ouverture)
      end
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

        it "allows read/write operations" do
          expect(policy.new?).to       be true
          expect(policy.show?).to      be true
          expect(policy.versions?).to  be true
          expect(policy.create?).to    be true
          expect(policy.edit?).to      be true
          expect(policy.update?).to    be true
          expect(policy.destroy?).to   be true

          expect(policy_scope).to include(plage_ouverture)
        end
      end

      context "when she shares no service with the plage's agent" do
        before do
          expect(agent.services.to_set.intersection(plage_ouverture.agent.services.to_set)).to be_empty # rubocop:disable RSpec/ExpectInHook
        end

        it "allows read/write operations" do
          expect(policy.new?).to       be false
          expect(policy.create?).to    be false
          expect(policy.edit?).to      be false
          expect(policy.update?).to    be false
          expect(policy.destroy?).to   be false
          expect(policy.show?).to      be false
          expect(policy.versions?).to  be false

          expect(policy_scope).not_to include(plage_ouverture)
        end
      end
    end

    context "when she belongs to the plage's organisation as admin member" do
      let(:agent) { create(:agent, admin_role_in_organisations: [plage_ouverture.organisation]) }

      it "allows read/write operations" do
        expect(policy.new?).to be true
        expect(policy.create?).to    be true
        expect(policy.edit?).to      be true
        expect(policy.update?).to    be true
        expect(policy.destroy?).to   be true
        expect(policy.show?).to      be true
        expect(policy.versions?).to  be true

        expect(policy_scope).to include(plage_ouverture)
      end
    end
  end
end

# frozen_string_literal: true

describe Agent::UserPolicy, type: :policy do
  subject { described_class }

  describe "creating user is always allowed" do
    let(:organisation) { create(:organisation) }
    let(:user) { build(:user, organisations: [organisation]) }
    let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
    let(:pundit_context) { AgentOrganisationContext.new(agent, organisation) }

    permissions :create? do
      it { is_expected.to permit(pundit_context, user) }
    end
  end

  describe "scope" do
    it "returns empty without users" do
      organisation = create(:organisation)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      policy = described_class::Scope.new(AgentOrganisationContext.new(agent, organisation), User)
      expect(policy.resolve).to be_empty
    end

    it "user of organisation" do
      organisation = create(:organisation)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      user = create(:user, organisations: [organisation])
      create(:user, organisations: [create(:organisation)])
      policy = described_class::Scope.new(AgentOrganisationContext.new(agent, organisation), User)
      expect(policy.resolve).to eq([user])
    end
  end
end

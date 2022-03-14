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
end

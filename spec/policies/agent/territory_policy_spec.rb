RSpec.describe Agent::TerritoryPolicy, type: :policy do
  subject { described_class }

  let(:territory) { create(:territory) }
  let(:pundit_context) { agent }

  describe "agent with" do
    context "no admin access to this territory and no access_rights" do
      let(:agent) { create(:agent, role_in_territories: []) }
      let!(:access_rights) { create(:agent_territorial_access_right, agent: agent, territory: territory) }

      it_behaves_like "not permit actions",
                      :territory,
                      :show?,
                      :update?,
                      :edit?
    end

    context "admin access to this territory" do
      let(:territory) { create(:territory) }
      let(:agent) { create(:agent, role_in_territories: [territory]) }
      let!(:access_rights) { create(:agent_territorial_access_right, agent: agent, territory: territory) }

      it_behaves_like "permit actions",
                      :territory,
                      :show?,
                      :update?,
                      :edit?
    end

    context "allowed to manage teams access right" do
      let(:agent) { create(:agent, role_in_territories: []) }
      let!(:access_rights) { create(:agent_territorial_access_right, agent: agent, territory: territory, allow_to_manage_teams: true) }

      it_behaves_like "permit actions", :territory, :show?

      it_behaves_like "not permit actions", :territory, :update?, :edit?
    end

    context "allowed to manage access rights access right" do
      let(:agent) { create(:agent, role_in_territories: []) }
      let!(:access_rights) { create(:agent_territorial_access_right, agent: agent, territory: territory, allow_to_manage_access_rights: true) }

      it_behaves_like "permit actions", :territory, :show?

      it_behaves_like "not permit actions", :territory, :update?, :edit?
    end

    context "allowed to invite agents access right" do
      let(:agent) { create(:agent, role_in_territories: []) }
      let!(:access_rights) { create(:agent_territorial_access_right, agent: agent, territory: territory, allow_to_invite_agents: true) }

      it_behaves_like "permit actions", :territory, :show?

      it_behaves_like "not permit actions", :territory, :update?, :edit?
    end
  end
end

RSpec.describe Agent::TerritoryPolicy::Scope, type: :policy do
  describe "#resolve?" do
    subject do
      described_class.new(agent, Territory).resolve
    end

    context "misc state" do
      let!(:territory1) { create(:territory) }
      let!(:territory2) { create(:territory) }
      let!(:territory3) { create(:territory) }
      let!(:agent) { create(:agent, role_in_territories: [territory1, territory2]) }

      it { is_expected.to include(territory1) }
      it { is_expected.to include(territory2) }
      it { is_expected.not_to include(territory3) }
    end
  end
end

# frozen_string_literal: true

describe AgentRole, type: :model do
  describe "#can_access_others_planning?" do
    subject { agent_role.can_access_others_planning? }

    context "admin access_level" do
      let(:agent_role) { build(:agent_role, :admin) }

      it { is_expected.to be_truthy }
    end

    context "basic access_level, but agent is secretaire" do
      let(:agent) { build(:agent, :secretaire) }
      let(:agent_role) { build(:agent_role, agent: agent) }

      it { is_expected.to be_truthy }
    end

    context "basic access_level" do
      let(:agent_role) { build(:agent_role, access_level: AgentRole::ACCESS_LEVEL_BASIC) }

      it { is_expected.to be_falsy }
    end
  end

  describe "#organisation_cannot_change validation" do
    let!(:organisation) { create(:organisation) }
    let!(:agent_role1) { create(:agent_role, access_level: AgentRole::ACCESS_LEVEL_ADMIN, organisation: organisation) }
    let!(:agent_role2) { create(:agent_role, access_level: AgentRole::ACCESS_LEVEL_ADMIN, organisation: organisation) } # needed to avoid validation error for orga without admin
    let!(:other_orga) { create(:organisation) }

    it "does not allow change" do
      result = agent_role1.update(organisation: other_orga)
      expect(result).to be_falsey
      expect(agent_role1.reload.organisation).to eq(organisation)
    end

    it "allows for another kind of update" do
      result = agent_role1.update(access_level: AgentRole::ACCESS_LEVEL_BASIC)
      expect(result).to be_truthy
      expect(agent_role1.reload.access_level).to eq(AgentRole::ACCESS_LEVEL_BASIC)
    end
  end

  describe "#organisations_have_at_least_one_admin validation" do
    context "there is another admin" do
      let!(:organisation) { create(:organisation) }
      let!(:agent_role1) { create(:agent_role, access_level: AgentRole::ACCESS_LEVEL_ADMIN, organisation: organisation) }
      let!(:agent_role2) { create(:agent_role, access_level: AgentRole::ACCESS_LEVEL_ADMIN, organisation: organisation) }

      it "allows downgrading one agent" do
        result = agent_role1.update(access_level: AgentRole::ACCESS_LEVEL_BASIC)
        expect(result).to be_truthy
        expect(agent_role1.reload.access_level).to eq(AgentRole::ACCESS_LEVEL_BASIC)
      end
    end

    context "there are no other admins" do
      let!(:organisation) { create(:organisation) }
      let!(:agent_role1) { create(:agent_role, access_level: AgentRole::ACCESS_LEVEL_ADMIN, organisation: organisation) }
      let!(:agent_role2) { create(:agent_role, access_level: AgentRole::ACCESS_LEVEL_BASIC, organisation: organisation) }

      it "forbids downgrading admin" do
        result = agent_role1.update(access_level: AgentRole::ACCESS_LEVEL_BASIC)
        expect(result).to be_falsey
        expect(agent_role1.errors).not_to be_empty
        expect(agent_role1.reload.access_level).to eq(AgentRole::ACCESS_LEVEL_ADMIN)
      end
    end
  end

  describe "#organisation_have_at_least_one_admin_before_destroy" do
    context "there is another admin" do
      let!(:organisation) { create(:organisation) }
      let!(:agent_role1) { create(:agent_role, access_level: AgentRole::ACCESS_LEVEL_ADMIN, organisation: organisation) }
      let!(:agent_role2) { create(:agent_role, access_level: AgentRole::ACCESS_LEVEL_ADMIN, organisation: organisation) }

      it "allows destroying one agent" do
        agent_role1.destroy
        expect(organisation.agent_roles.count).to eq 1
      end
    end

    context "there are no other admins" do
      let!(:organisation) { create(:organisation) }
      let!(:agent_role1) { create(:agent_role, access_level: AgentRole::ACCESS_LEVEL_ADMIN, organisation: organisation) }
      let!(:agent_role2) { create(:agent_role, access_level: AgentRole::ACCESS_LEVEL_BASIC, organisation: organisation) }

      it "forbids destroying admin" do
        agent_role1.destroy
        expect(agent_role1.errors).not_to be_empty
        expect(organisation.agent_roles.count).to eq 2
      end
    end
  end

  describe "uniqueness error differ if the agent has not accepted the invitation yet" do
    subject { build(:agent_role, agent: agent, organisation: organisation) }

    let(:organisation) { build(:organisation) }
    let(:agent) { build(:agent, invitation_accepted_at: invitation_accepted_at) }

    before do
      create(:agent_role, agent: agent, organisation: organisation) # existing role
      subject.validate
    end

    context "agent has already accepted the invitation" do
      let(:invitation_accepted_at) { Time.zone.now }

      it { expect(subject.errors.details.dig(:agent, 0, :error)).to eq :taken_existing }
    end

    context "agent has not yet accepted the invitation" do
      let(:invitation_accepted_at) { nil }

      it { expect(subject.errors.details.dig(:agent, 0, :error)).to eq :taken_invited }
    end
  end
end

describe AgentRole, type: :model do
  describe "#can_access_others_planning?" do
    subject { agent_role.can_access_others_planning? }

    context "admin level" do
      let(:agent_role) { build(:agent_role, :admin) }

      it { is_expected.to be_truthy }
    end

    context "basic level, but agent is secretaire" do
      let(:agent) { build(:agent, :secretaire) }
      let(:agent_role) { build(:agent_role, agent: agent) }

      it { is_expected.to be_truthy }
    end

    context "basic level" do
      let(:agent_role) { build(:agent_role, level: AgentRole::LEVEL_BASIC) }

      it { is_expected.to be_falsy }
    end
  end

  describe "#organisation_cannot_change validation" do
    let!(:organisation) { create(:organisation) }
    let!(:agent_role1) { create(:agent_role, level: AgentRole::LEVEL_ADMIN, organisation: organisation) }
    let!(:agent_role2) { create(:agent_role, level: AgentRole::LEVEL_ADMIN, organisation: organisation) } # needed to avoid validation error for orga without admin
    let!(:other_orga) { create(:organisation) }

    it "does not allow change" do
      result = agent_role1.update(organisation: other_orga)
      expect(result).to be_falsey
      expect(agent_role1.reload.organisation).to eq(organisation)
    end

    it "allows for another kind of update" do
      result = agent_role1.update(level: AgentRole::LEVEL_BASIC)
      expect(result).to be_truthy
      expect(agent_role1.reload.level).to eq(AgentRole::LEVEL_BASIC)
    end
  end

  describe "#organisations_have_at_least_one_admin validation" do
    context "there is another admin" do
      let!(:organisation) { create(:organisation) }
      let!(:agent_role1) { create(:agent_role, level: AgentRole::LEVEL_ADMIN, organisation: organisation) }
      let!(:agent_role2) { create(:agent_role, level: AgentRole::LEVEL_ADMIN, organisation: organisation) }

      it "allows downgrading one agent" do
        result = agent_role1.update(level: AgentRole::LEVEL_BASIC)
        expect(result).to be_truthy
        expect(agent_role1.reload.level).to eq(AgentRole::LEVEL_BASIC)
      end
    end

    context "there are no other admins" do
      let!(:organisation) { create(:organisation) }
      let!(:agent_role1) { create(:agent_role, level: AgentRole::LEVEL_ADMIN, organisation: organisation) }
      let!(:agent_role2) { create(:agent_role, level: AgentRole::LEVEL_BASIC, organisation: organisation) }

      it "forbids downgrading admin" do
        result = agent_role1.update(level: AgentRole::LEVEL_BASIC)
        expect(result).to be_falsey
        expect(agent_role1.errors).not_to be_empty
        expect(agent_role1.reload.level).to eq(AgentRole::LEVEL_ADMIN)
      end
    end
  end

  describe "#organisation_have_at_least_one_admin_before_destroy" do
    context "there is another admin" do
      let!(:organisation) { create(:organisation) }
      let!(:agent_role1) { create(:agent_role, level: AgentRole::LEVEL_ADMIN, organisation: organisation) }
      let!(:agent_role2) { create(:agent_role, level: AgentRole::LEVEL_ADMIN, organisation: organisation) }

      it "allows destroying one agent" do
        agent_role1.destroy
        expect(organisation.agent_roles.count).to eq 1
      end
    end

    context "there are no other admins" do
      let!(:organisation) { create(:organisation) }
      let!(:agent_role1) { create(:agent_role, level: AgentRole::LEVEL_ADMIN, organisation: organisation) }
      let!(:agent_role2) { create(:agent_role, level: AgentRole::LEVEL_BASIC, organisation: organisation) }

      it "forbids destroying admin" do
        agent_role1.destroy
        expect(agent_role1.errors).not_to be_empty
        expect(organisation.agent_roles.count).to eq 2
      end
    end
  end
end

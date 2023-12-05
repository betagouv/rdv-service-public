describe Agent::LieuPolicy do
  subject(:policy) { described_class.new(agent, lieu) }

  let!(:lieu) { create(:lieu) }

  context "for a basic agent in the lieu's org" do
    let(:agent) { create(:agent, basic_role_in_organisations: [lieu.organisation]) }

    it "does not allow any write operation on lieu" do
      expect(policy.new?).to be(false)
      expect(policy.create?).to be(false)
      expect(policy.edit?).to be(false)
      expect(policy.update?).to be(false)
      expect(policy.destroy?).to be(false)

      expect(policy.versions?).to be(false)
    end
  end

  context "for a admin agent of a different organisation" do
    let(:agent) { create(:agent, admin_role_in_organisations: [create(:organisation)]) }

    it "does not allow any write operation on lieu" do
      expect(policy.new?).to be(false)
      expect(policy.create?).to be(false)
      expect(policy.edit?).to be(false)
      expect(policy.update?).to be(false)
      expect(policy.destroy?).to be(false)

      expect(policy.versions?).to be(false)
    end
  end

  context "for a secretaire" do
    let(:agent) { create(:agent, :secretaire, basic_role_in_organisations: [lieu.organisation]) }

    it "does not allow any write operation on lieu" do
      expect(policy.new?).to be(false)
      expect(policy.create?).to be(false)
      expect(policy.edit?).to be(false)
      expect(policy.update?).to be(false)
      expect(policy.destroy?).to be(false)

      expect(policy.versions?).to be(false)
    end
  end

  context "for an organisation admin" do
    let(:agent) { create(:agent, admin_role_in_organisations: [lieu.organisation]) }

    it "allows creating, updating and destroying the lieu, plus seeing the versions" do
      expect(policy.new?).to be(true)
      expect(policy.create?).to be(true)
      expect(policy.edit?).to be(true)
      expect(policy.update?).to be(true)
      expect(policy.destroy?).to be(true)

      expect(policy.versions?).to be(true)
    end
  end

  describe Agent::LieuPolicy::Scope do
    subject(:scope) { described_class.apply(agent, Lieu) }

    let!(:basic_org) { create(:organisation) }
    let!(:admin_org) { create(:organisation) }
    let!(:other_org) { create(:organisation) }
    let!(:agent) { create(:agent, basic_role_in_organisations: [basic_org], admin_role_in_organisations: [admin_org]) }
    let!(:lieu_in_basic_org) { create(:lieu, organisation: basic_org) }
    let!(:lieu_in_admin_org) { create(:lieu, organisation: admin_org) }
    let!(:lieu_in_other_org) { create(:lieu, organisation: other_org) }

    it "includes lieux of organisations when agent is basic or admin" do
      expect(scope).to contain_exactly(lieu_in_basic_org, lieu_in_admin_org)
    end
  end
end

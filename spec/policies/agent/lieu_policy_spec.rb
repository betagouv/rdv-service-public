# rubocop:disable RSpec/PredicateMatcher
describe Agent::LieuPolicy do
  subject(:policy) { described_class.new(agent, lieu) }

  let!(:lieu) { create(:lieu) }

  context "for a basic agent in the lieu's org" do
    let(:agent) { create(:agent, basic_role_in_organisations: [lieu.organisation]) }

    it "does not allow any write operation on lieu" do
      expect(policy.new?).to be_falsey
      expect(policy.create?).to be_falsey
      expect(policy.edit?).to be_falsey
      expect(policy.update?).to be_falsey
      expect(policy.destroy?).to be_falsey

      expect(policy.versions?).to be_falsey
    end
  end

  context "for a admin agent of a different organisation" do
    let(:agent) { create(:agent, admin_role_in_organisations: [create(:organisation)]) }

    it "does not allow any write operation on lieu" do
      expect(policy.new?).to be_falsey
      expect(policy.create?).to be_falsey
      expect(policy.edit?).to be_falsey
      expect(policy.update?).to be_falsey
      expect(policy.destroy?).to be_falsey

      expect(policy.versions?).to be_falsey
    end
  end

  context "for a secretaire" do
    let(:agent) { create(:agent, :secretaire, basic_role_in_organisations: [lieu.organisation]) }

    it "does not allow any write operation on lieu" do
      expect(policy.new?).to be_falsey
      expect(policy.create?).to be_falsey
      expect(policy.edit?).to be_falsey
      expect(policy.update?).to be_falsey
      expect(policy.destroy?).to be_falsey

      expect(policy.versions?).to be_falsey
    end
  end

  context "for an organisation admin" do
    let(:agent) { create(:agent, admin_role_in_organisations: [lieu.organisation]) }

    it "allows creating, updating and destroying the lieu, plus seeing the versions" do
      expect(policy.new?).to be_truthy
      expect(policy.create?).to be_truthy
      expect(policy.edit?).to be_truthy
      expect(policy.update?).to be_truthy
      expect(policy.destroy?).to be_truthy

      expect(policy.versions?).to be_truthy
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
# rubocop:enable RSpec/PredicateMatcher

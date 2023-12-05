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
end
# rubocop:enable RSpec/PredicateMatcher

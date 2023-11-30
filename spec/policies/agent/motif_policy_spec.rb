describe Agent::MotifPolicy do
  subject { described_class }

  let!(:motif) { create(:motif) }

  context "for a basic agent of the same service" do
    let(:agent) { create(:agent, basic_role_in_organisations: [motif.organisation], service: motif.service) }

    it "allows seeing but not modifying the motif" do
      policy = described_class.new(agent, motif)
      expect(policy.show?).to be_truthy

      expect(policy.new?).to be_falsey
      expect(policy.create?).to be_falsey
      expect(policy.edit?).to be_falsey
      expect(policy.update?).to be_falsey
      expect(policy.destroy?).to be_falsey

      expect(policy.versions?).to be_falsey
    end
  end

  context "for a basic agent of a different service" do
    let(:agent) { create(:agent, basic_role_in_organisations: [motif.organisation], service: create(:service)) }

    it "doesn't allow seeing or modifying the motif" do
      policy = described_class.new(agent, motif)
      expect(policy.show?).to be_falsey

      expect(policy.new?).to be_falsey
      expect(policy.create?).to be_falsey
      expect(policy.edit?).to be_falsey
      expect(policy.update?).to be_falsey
      expect(policy.destroy?).to be_falsey

      expect(policy.versions?).to be_falsey
    end
  end

  context "for a secretaire" do
    let(:agent) { create(:agent, basic_role_in_organisations: [motif.organisation], service: create(:service, :secretariat)) }

    it "allows seeing but not modifying the motif" do
      policy = described_class.new(agent, motif)
      expect(policy.show?).to be_truthy

      expect(policy.new?).to be_falsey
      expect(policy.create?).to be_falsey
      expect(policy.edit?).to be_falsey
      expect(policy.update?).to be_falsey
      expect(policy.destroy?).to be_falsey

      expect(policy.versions?).to be_falsey
    end
  end

  context "for an organisation admin" do
  end

  context "for the admin of a different organisation" do
  end
end

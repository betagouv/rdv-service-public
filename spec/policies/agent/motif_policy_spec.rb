RSpec.describe Agent::MotifPolicy do
  subject { described_class }

  let!(:motif) { create(:motif, service: service) }
  let(:service) { create(:service) }

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

  context "for a basic agent when the motif doesn't have a service" do
    let(:agent) { create(:agent, basic_role_in_organisations: [motif.organisation], service: service) }

    let!(:motif) { create(:motif, service: nil) }

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
    let(:agent) { create(:agent, admin_role_in_organisations: [motif.organisation], service: create(:service)) }

    it "allows seeing and modifying the motif" do
      policy = described_class.new(agent, motif)
      expect(policy.show?).to be_truthy

      expect(policy.new?).to be_truthy
      expect(policy.create?).to be_truthy
      expect(policy.edit?).to be_truthy
      expect(policy.update?).to be_truthy
      expect(policy.destroy?).to be_truthy

      expect(policy.versions?).to be_truthy
    end

    context "when the motif doesn't have a service" do
      let!(:motif) { create(:motif, service: nil) }

      it "allows seeing and modifying the motif" do
        policy = described_class.new(agent, motif)
        expect(policy.show?).to be_truthy

        expect(policy.new?).to be_truthy
        expect(policy.create?).to be_truthy
        expect(policy.edit?).to be_truthy
        expect(policy.update?).to be_truthy
        expect(policy.destroy?).to be_truthy

        expect(policy.versions?).to be_truthy
      end
    end
  end

  context "for the admin of a different organisation" do
    let(:agent) { create(:agent, admin_role_in_organisations: [create(:organisation)], service: motif.service) }

    it "allows nothing" do
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

  describe Agent::MotifPolicy::Scope do
    context "for a basic agent" do
      let(:agent) { create(:agent, basic_role_in_organisations: [motif.organisation], service: motif.service) }
      let!(:motif_without_service) { create(:motif, service: nil, organisation: motif.organisation) }
      let!(:motif_from_other_service) { create(:motif, service: create(:service), organisation: motif.organisation) }

      it "returns the motifs of the agent's service and the motifs without services" do
        visible_motifs = described_class.new(agent, Motif.all).resolve
        expect(visible_motifs).to contain_exactly(motif, motif_without_service)
      end
    end
  end
end

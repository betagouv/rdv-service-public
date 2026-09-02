RSpec.describe Agent::RdvInvitationPolicy do
  subject { described_class.new(agent, rdv_invitation) }

  let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let(:organisation) { create(:organisation) }

  let(:rdv_invitation) { create(:rdv_invitation, motif:, lieu:, user:, inviting_agent: agent) }

  let(:motif) { create(:motif, organisation:) }
  let(:lieu) { create(:lieu, organisation:) }
  let(:user) { create(:user, organisations: [organisation]) }

  context "when the motif, lieu, and user are visible" do
    it "is allowed" do
      expect(subject.new?).to be_truthy
      expect(subject.create?).to be_truthy
      expect(subject.show?).to be_truthy
    end

    context "without a lieu" do
      let(:lieu) { nil }

      it "is allowed" do
        expect(subject.new?).to be_truthy
        expect(subject.create?).to be_truthy
        expect(subject.show?).to be_truthy
      end
    end
  end

  context "when the user is not in the agent's organisations" do
    let(:user) { create(:user, organisations: [create(:organisation)]) }

    it "is forbidden" do
      expect(subject.new?).to be_falsey
      expect(subject.create?).to be_falsey
      expect(subject.show?).to be_falsey
    end
  end

  context "when the motif is not in the agent's organisations" do
    let(:motif) { create(:motif, organisation: create(:organisation)) }

    it "is forbidden" do
      expect(subject.new?).to be_falsey
      expect(subject.create?).to be_falsey
      expect(subject.show?).to be_falsey
    end
  end

  context "when the lieu is not in the agent's organisations" do
    let(:lieu) { create(:lieu, organisation: create(:organisation)) }

    it "is forbidden" do
      expect(subject.new?).to be_falsey
      expect(subject.create?).to be_falsey
      expect(subject.show?).to be_falsey
    end
  end
end

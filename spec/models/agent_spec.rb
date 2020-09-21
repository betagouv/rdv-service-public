describe Agent, type: :model do
  describe "#soft_delete" do
    context "with many remaining organisations" do
      before { agent.soft_delete deleted_org }
      let(:agent) { create(:agent, :with_multiple_organisations) }
      let(:deleted_org) { agent.organisations.first }
      it { expect(agent.organisation_ids).not_to include(deleted_org.id) }
      it { expect(agent.deleted_at).to be_nil }
    end

    context "with one remaining organisations" do
      let!(:agent) { create(:agent) }
      let(:deleted_org) { agent.organisations.first }

      context "without rdv" do
        it { expect { agent.soft_delete deleted_org }.to change(Agent, :count).by(-1) }
      end

      context "with rdv" do
        let!(:rdv) { create(:rdv, agent_ids: [agent.id]) }
        before { agent.soft_delete deleted_org }

        it { expect(agent.deleted_at).not_to be_nil }
      end
    end

    context "with no organisation given" do
      let!(:agent) { create(:agent, :with_multiple_organisations) }
      let(:deleted_org) { nil }

      it { expect { agent.soft_delete deleted_org }.to change(Agent, :count).by(-1) }
    end

    it "keep old mail in an `email_original` attribute" do
      organisation = create(:organisation)
      agent = create(:agent, email: "karim@le64.fr", organisations: [organisation])
      create(:rdv, agents: [agent])
      agent.soft_delete(organisation)
      expect(agent.email_original).to eq("karim@le64.fr")
    end

    it "update mail with a deleted_mail (agent_\#{id}@deleted.rdv-solidarites.fr" do
      organisation = create(:organisation)
      agent = create(:agent, organisations: [organisation])
      create(:rdv, agents: [agent])
      agent.soft_delete(organisation)
      expect(agent.email).to eq("agent_#{agent.id}@deleted.rdv-solidarites.fr")
    end
  end

  describe "#can_access_others_planning?" do
    it "return true when agent is admin" do
      admin = create(:agent, :admin)
      expect(admin.can_access_others_planning?).to be_truthy
    end

    it "return true when agent is secretaire" do
      secretaire = create(:agent, :secretaire)
      expect(secretaire.can_access_others_planning?).to be_truthy
    end

    it "return false with a classical agent" do
      secretaire = create(:agent)
      expect(secretaire.can_access_others_planning?).to be_falsy
    end
  end
end

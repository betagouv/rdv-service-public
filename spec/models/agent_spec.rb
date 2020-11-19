describe Agent, type: :model do
  describe "#soft_delete" do
    context "with remaining organisations attached" do
      let(:organisation) { create(:organisation) }
      let(:agent) { create(:agent, organisations: [organisation]) }

      it "should raise" do
        expect { agent.soft_delete }.to raise_error SoftDeleteError
      end
    end

    context "without organisations" do
      let!(:agent) { create(:agent, organisations: []) }

      it "should mark agent as soft deleted" do
        agent.soft_delete
        expect(agent.deleted_at).to be_present
      end
    end

    it "keep old mail in an `email_original` attribute" do
      agent = create(:agent, email: "karim@le64.fr", organisations: [])
      create(:rdv, agents: [agent])
      agent.soft_delete
      expect(agent.email_original).to eq("karim@le64.fr")
    end

    it "update mail with a deleted_mail (agent_\#{id}@deleted.rdv-solidarites.fr" do
      agent = create(:agent, organisations: [])
      create(:rdv, agents: [agent])
      agent.soft_delete
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

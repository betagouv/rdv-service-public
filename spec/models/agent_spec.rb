describe Agent, type: :model do
  describe "#soft_delete" do
    context "with remaining organisations attached" do
      let(:organisation) { create(:organisation) }
      let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      it "should raise" do
        expect { agent.soft_delete }.to raise_error SoftDeleteError
      end
    end

    context "without organisations" do
      let!(:agent) { create(:agent) }

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

    it "update mail with a unique value" do
      agent = create(:agent, basic_role_in_organisations: [])
      create(:rdv, agents: [agent])
      agent.soft_delete
      expect(agent.email).to eq("agent_#{agent.id}@deleted.rdv-solidarites.fr")
    end

    it "update UID with a unique value" do
      agent = create(:agent, basic_role_in_organisations: [])
      create(:rdv, agents: [agent])
      agent.soft_delete
      expect(agent.uid).to eq("agent_#{agent.id}@deleted.rdv-solidarites.fr")
    end
  end

  describe "#only_in_this_organisation?" do
    it "return true when single orga left" do
      organisation = build(:organisation)
      agent = build(:agent, organisations: [organisation])
      expect(agent.only_in_this_organisation?(organisation)).to be true
    end

    it "return true when no orga left" do
      organisation = build(:organisation)
      agent = build(:agent, organisations: [])
      expect(agent.only_in_this_organisation?(organisation)).to be true
    end

    it "return false when orgas left" do
      organisation = build(:organisation)
      other_organisation = build(:organisation)
      agent = build(:agent, organisations: [organisation, other_organisation])
      expect(agent.only_in_this_organisation?(organisation)).to be false
    end
  end
end

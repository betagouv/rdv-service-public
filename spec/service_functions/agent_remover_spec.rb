describe AgentRemover, type: :service do

  context "agent belongs to single organisation, with a few absences and plages ouvertures" do
    it "should succeed" do
      organisation = create(:organisation)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      expect(AgentRemover.remove!(agent, organisation)).to eq true
    end

    it "should destroy absences" do
      organisation = create(:organisation)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      absences = create_list(:absence, 2, agent: agent, organisation: organisation)
      AgentRemover.remove!(agent, organisation)
      expect(agent.absences).to be_empty
    end

    it "should destroy plages ouvertures" do
      organisation = create(:organisation)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      plage_ouvertures = create_list(:plage_ouverture, 2, agent: agent, organisation: organisation)
      AgentRemover.remove!(agent, organisation)
      expect(agent.plage_ouvertures).to be_empty
    end

    it "soft_delete" do
      organisation = create(:organisation)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      expect(agent).to receive(:soft_delete)
      AgentRemover.remove!(agent, organisation)
    end

    it "should remove organisation's agent link" do
      organisation = create(:organisation)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      result = AgentRemover.remove!(agent, organisation)
      expect(agent.reload.organisations).to be_empty
    end
  end

  context "agent belongs to multiple organisations" do
    it "should succeed and destroy absences and plages ouvertures and not soft delete" do
      organisation1 = create(:organisation)
      organisation2 = create(:organisation)
      agent = create(:agent, basic_role_in_organisations: [organisation1, organisation2])
      plage_ouvertures1 = create_list(:plage_ouverture, 2, agent: agent, organisation: organisation1)
      absences1 = create_list(:absence, 2, agent: agent, organisation: organisation1)
      plage_ouvertures2 = create_list(:plage_ouverture, 2, agent: agent, organisation: organisation2)
      absences2 = create_list(:absence, 2, agent: agent, organisation: organisation2)


      expect(agent).not_to receive(:soft_delete)
      result = AgentRemoval.remove!(agent, organisation1)
      expect(result).to eq true
      expect(agent.organisations).to contain_exactly(organisation2)
      expect(agent.plage_ouvertures).to contain_exactly(*plage_ouvertures2)
      expect(agent.absences).to contain_exactly(*absences2)
    end
  end

  context "agent has upcoming RDVs" do
    let!(:organisation) { create(:organisation) }
    let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
    let!(:rdv) do
      rdv = build(:rdv, agents: [agent], organisation: organisation, starts_at: Date.today.next_week(:monday) + 10.hours)
      rdv.define_singleton_method(:notify_rdv_created) {}
      rdv.save!
      rdv
    end

    it "should not succeed" do
      expect(agent).not_to receive(:soft_delete)
      result = AgentRemoval.remove!(agent, organisation)
      expect(result).to eq false
      expect(agent.organisations).to include(organisation)
    end
  end

  context "agent has old RDVs" do
    let!(:organisation) { create(:organisation) }
    let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
    let!(:rdv) do
      rdv = build(:rdv, agents: [agent], organisation: organisation, starts_at: Date.today.prev_week(:monday) + 10.hours)
      rdv.define_singleton_method(:notify_rdv_created) {}
      rdv.save!
      rdv
    end

    it "should succeed" do
      expect(agent).to receive(:soft_delete)
      result = AgentRemoval.remove!(agent, organisation)
      expect(result).to eq true
      expect(agent.organisations).to be_empty
    end
  end
end

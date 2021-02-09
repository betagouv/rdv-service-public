describe AgentRemoval, type: :service do
  context "agent belongs to single organisation, with a few absences and plages ouvertures" do
    let!(:organisation) { create(:organisation) }
    let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
    let!(:plage_ouvertures) { create_list(:plage_ouverture, 2, agent: agent, organisation: organisation) }
    let!(:absences) { create_list(:absence, 2, agent: agent, organisation: organisation) }

    it "should succeed, destroy absences and plages ouvertures, and soft delete" do
      expect(agent).to receive(:soft_delete)
      result = AgentRemoval.new(agent, organisation).remove!
      expect(result).to eq true
      expect(agent.organisations).to be_empty
      expect(agent.absences).to be_empty
      expect(agent.plage_ouvertures).to be_empty
    end
  end

  context "agent belongs to multiple organisations" do
    let!(:organisation1) { create(:organisation) }
    let!(:organisation2) { create(:organisation) }
    let!(:agent) { create(:agent, basic_role_in_organisations: [organisation1, organisation2]) }
    let!(:plage_ouvertures1) { create_list(:plage_ouverture, 2, agent: agent, organisation: organisation1) }
    let!(:absences1) { create_list(:absence, 2, agent: agent, organisation: organisation1) }
    let!(:plage_ouvertures2) { create_list(:plage_ouverture, 2, agent: agent, organisation: organisation2) }
    let!(:absences2) { create_list(:absence, 2, agent: agent, organisation: organisation2) }

    it "should succeed and destroy absences and plages ouvertures and not soft delete" do
      expect(agent).not_to receive(:soft_delete)
      result = AgentRemoval.new(agent, organisation1).remove!
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
      result = AgentRemoval.new(agent, organisation).remove!
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
      result = AgentRemoval.new(agent, organisation).remove!
      expect(result).to eq true
      expect(agent.organisations).to be_empty
    end
  end

  describe "#should_soft_delete?" do
    subject { AgentRemoval.new(agent, organisation1).should_soft_delete? }
    let(:organisation1) { build(:organisation) }

    context "single orga left" do
      let(:agent) { build(:agent, organisations: [organisation1]) }
      it { should eq true }
    end

    context "no orga left" do
      let(:agent) { build(:agent, organisations: []) }
      it { should eq true }
    end

    context "multiple orgas left" do
      let(:organisation2) { build(:organisation) }
      let(:agent) { build(:agent, organisations: [organisation1, organisation2]) }
      it { should eq false }
    end
  end
end

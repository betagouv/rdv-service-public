RSpec.describe AgentRemoval, type: :service do
  context "agent belongs to single organisation, with a few absences and plages ouvertures" do
    # orgs must have at least one admin
    let!(:admin_agent) { create(:agent, admin_role_in_organisations: [organisation]) }
    let!(:organisation) { create(:organisation) }
    let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
    let!(:plage_ouvertures) { create_list(:plage_ouverture, 2, agent: agent, organisation: organisation) }
    let!(:absences) { create_list(:absence, 2, agent: agent) }

    it "succeeds destroy absences and plages ouvertures, and soft delete" do
      service = described_class.new(agent, organisation)
      expect(service).to be_valid
      service.remove!
      agent.reload
      expect(agent.organisations).to be_empty
      expect(agent.absences).to be_empty
      expect(agent.plage_ouvertures).to be_empty
      expect(agent.deleted_at).not_to be_nil
    end
  end

  context "agent belongs to multiple organisations" do
    # orgs must have at least one admin
    let!(:admin_agent) { create(:agent, admin_role_in_organisations: [organisation1, organisation2]) }
    let!(:organisation1) { create(:organisation) }
    let!(:organisation2) { create(:organisation) }
    let!(:agent) { create(:agent, basic_role_in_organisations: [organisation1, organisation2]) }
    let!(:plage_ouvertures1) { create_list(:plage_ouverture, 2, agent: agent, organisation: organisation1) }
    let!(:plage_ouvertures2) { create_list(:plage_ouverture, 2, agent: agent, organisation: organisation2) }
    let!(:absences) { create_list(:absence, 2, agent: agent) }

    it "succeeds and destroy absences and plages ouvertures and not soft delete" do
      expect(agent).not_to receive(:soft_delete)
      service = described_class.new(agent, organisation1)
      expect(service).to be_valid
      service.remove!
      agent.reload
      expect(agent.organisations).to contain_exactly(organisation2)
      expect(agent.plage_ouvertures).to match_array(plage_ouvertures2)
      expect(agent.absences).to match_array(absences)
    end
  end

  context "agent has upcoming RDVs" do
    # orgs must have at least one admin
    let!(:admin_agent) { create(:agent, admin_role_in_organisations: [organisation]) }
    let!(:organisation) { create(:organisation) }
    let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
    let!(:rdv) { create(:rdv, agents: [agent], organisation: organisation, starts_at: Time.zone.today.next_week(:monday) + 10.hours) }

    it "does not succeed" do
      expect(agent).not_to receive(:soft_delete)
      service = described_class.new(agent, organisation)
      expect(service).to be_invalid
      expect { service.remove! }.to raise_error(StandardError)
      expect(agent.organisations).to include(organisation)
    end
  end

  context "agent has old RDVs" do
    # orgs must have at least one admin
    let!(:admin_agent) { create(:agent, admin_role_in_organisations: [organisation]) }
    let!(:organisation) { create(:organisation) }

    it "succeeds" do
      now = Time.zone.parse("2021-02-13 13:00")
      travel_to(now - 2.weeks)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      create(:rdv, agents: [agent], organisation: organisation, starts_at: now.prev_week(:monday) + 10.hours)
      travel_to(now)

      expect(agent).to receive(:soft_delete)
      service = described_class.new(agent, organisation)
      expect(service).to be_valid
      service.remove!
      expect(agent.organisations).to be_empty
    end
  end

  context "when the agent is the only admin of the org" do
    let!(:organisation) { create(:organisation) }
    let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

    it "raises" do
      expect do
        described_class.new(agent, organisation).remove!
      end.to raise_error(ActiveRecord::RecordNotDestroyed)
    end
  end

  describe "#should_soft_delete?" do
    subject { described_class.new(agent, organisation1).should_soft_delete? }

    let(:organisation1) { build(:organisation) }

    context "single orga left" do
      let(:agent) { build(:agent, organisations: [organisation1]) }

      it { is_expected.to be true }
    end

    context "no orga left" do
      let(:agent) { build(:agent, organisations: []) }

      it { is_expected.to be true }
    end

    context "multiple orgas left" do
      let(:organisation2) { build(:organisation) }
      let(:agent) { build(:agent, organisations: [organisation1, organisation2]) }

      it { is_expected.to be false }
    end
  end
end

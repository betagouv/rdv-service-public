require "rails_helper"
require Rails.root.join("db/migrate/20260204155234_services_by_territory.rb")

RSpec.describe ServicesByTerritory, type: :migration do
  describe ".split_services_by_territory" do
    let!(:territory) { create(:territory) }
    let!(:organisation) { create(:organisation, territory:) }

    let!(:agent1) { create(:agent) }
    let!(:agent2) { create(:agent) }

    let!(:legacy_service) do
      create(:service, territory_id: nil, name: "Legacy Service", short_name: "LS")
    end

    let!(:agent_service1) do
      create(:agent_service, agent: agent1, service: legacy_service, created_at: 2.days.ago)
    end

    let!(:agent_service2) do
      create(:agent_service, agent: agent2, service: legacy_service, created_at: 1.day.ago)
    end

    let!(:motif) do
      create(:motif, organisation:, service: legacy_service)
    end

    before do
      create(:agent_territorial_access_right, territory:, agent: agent1)
      create(:agent_role, agent: agent2, organisation:)
    end

    it "creates a new service tied to the territory" do
      expect {
        described_class.split_services_by_territory
      }.to change {
        Service.where(name: "Legacy Service", territory_id: territory.id).count
      }.from(0).to(1)
    end

    it "creates new agent_services for the new service" do
      expect {
        described_class.split_services_by_territory
      }.to change {
        AgentService.where(service: legacy_service).count
      }.by(-2)
      expect(AgentService.where(agent: agent1).sole.service.name).to eq(legacy_service.name)
    end

    it "reassigns motifs to the new service" do
      described_class.split_services_by_territory

      new_service = Service.find_by(name: "Legacy Service", territory_id: territory.id)
      expect(motif.reload.service_id).to eq(new_service.id)
    end

    it "preserves created_at timestamps on agent_services" do
      described_class.split_services_by_territory

      new_service = Service.find_by(name: "Legacy Service", territory_id: territory.id)
      new_as = AgentService.find_by(agent: agent1, service: new_service)

      expect(new_as.created_at.to_i).to eq(agent_service1.created_at.to_i)
    end

    it "removes legacy services" do
      expect {
        described_class.split_services_by_territory
      }.to change {
        Service.where(id: legacy_service.id).count
      }.from(1).to(0)
    end

    it "removes legacy agent_services" do
      expect {
        described_class.split_services_by_territory
      }.to change {
        AgentService.where(service: legacy_service).count
      }.from(2).to(0)
    end
  end

  describe "with multiple territories" do
    let!(:territory1) { create(:territory) }
    let!(:territory2) { create(:territory) }

    let!(:organisation1) { create(:organisation, territory: territory1) }
    let!(:organisation2) { create(:organisation, territory: territory2) }

    let!(:agent1) { create(:agent) }
    let!(:agent2) { create(:agent) }

    let!(:legacy_service) { create(:service, name: "Shared", short_name: "S") }

    before do
      create(:agent_service, agent: agent1, service: legacy_service)
      create(:agent_service, agent: agent2, service: legacy_service)

      create(:agent_role, agent: agent1, organisation: organisation1)
      create(:agent_role, agent: agent2, organisation: organisation2)
    end

    it "creates one service per territory" do
      expect {
        described_class.split_services_by_territory
      }.to change {
        Service.where(name: "Shared").count
      }.from(1).to(2)

      expect(Service.where(name: "Shared").pluck(:territory_id))
        .to match_array([territory1.id, territory2.id])
    end
  end
end

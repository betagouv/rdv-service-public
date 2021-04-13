describe Admin::AgentRoleAndService, type: :service do
  describe "#update_with" do
    it "update level" do
      agent_role = create(:agent_role, level: "basic")
      level = "admin"
      service_ids = []
      described_class.update_with(agent_role, level, service_ids)
      agent_role.reload
      expect(agent_role.level).to eq("admin")
    end

    it "returns true when everything is ok" do
      agent_role = create(:agent_role, level: "basic")
      level = "admin"
      service_ids = []
      expect(described_class.update_with(agent_role, level, service_ids)).to eq(true)
    end

    it "returns false if agent_role from admin to basic && agent_role last admin of organisation" do
      agent_role = create(:agent_role, level: "admin")
      level = "basic"
      service_ids = []
      expect(described_class.update_with(agent_role, level, service_ids)).to eq(false)
    end

    it "add new service" do
      service = create(:service)
      agent = create(:agent, services: [service])
      agent_role = create(:agent_role, level: "admin", agent: agent)
      level = "admin"
      new_service = create(:service)
      service_ids = [service.id, new_service.id]
      described_class.update_with(agent_role, level, service_ids)
      expect(agent.reload.services.sort).to eq([service, new_service].sort)
    end
  end
end

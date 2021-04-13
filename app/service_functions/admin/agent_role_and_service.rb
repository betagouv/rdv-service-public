module Admin::AgentRoleAndService
  def self.update_with(agent_role, level, service_ids)
    agent_role.update(level: level) &&
      agent_role.agent.update(service_ids: service_ids)
  end
end

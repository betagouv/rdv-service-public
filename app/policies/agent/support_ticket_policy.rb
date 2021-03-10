class Agent::SupportTicketPolicy < DefaultAgentPolicy
  def create?
    @record.email == current_agent.email
  end
end

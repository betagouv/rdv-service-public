class Agent::SupportTicketPolicy < DefaultAgentPolicy
  def create?
    @record.email == @context.agent.email
  end
end

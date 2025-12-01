class AgendaChannel < ApplicationCable::Channel
  # Called when the consumer has successfully
  # become a subscriber to this channel.
  def subscribed
    agent = Agent::AgentPolicy::Scope.new(current_agent, Agent.all).resolve.find(params.fetch("agent_id"))
    stream_for agent.id
  rescue StandardError => e
    Sentry.capture_exception(e)
    reject
  end
end

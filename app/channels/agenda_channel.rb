class AgendaChannel < ApplicationCable::Channel
  # Called when the consumer has successfully
  # become a subscriber to this channel.
  def subscribed
    agent = Agent.find(params["agent_id"])
    stream_for agent.id
  end
end

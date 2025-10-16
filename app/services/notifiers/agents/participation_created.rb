class Notifiers::Agents::ParticipationCreated < BaseService
  include Notifiers::AgentsConcern

  attr_reader :participation

  delegate :rdv, to: :participation

  def initialize(participation:, author:)
    @participation = participation
    @author = author
  end

  def notify_agent(agent)
    Agents::RdvMailer.with(participation:, agent:).participation_created.deliver_later
  end
end

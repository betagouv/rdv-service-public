class Notifiers::Agents::ParticipationCreated < BaseService
  attr_reader :participation

  delegate :rdv, to: :participation

  def initialize(participation:, author:)
    @participation = participation
    @author = author
  end

  def notify_agents
    Notifiers::AgentsFilter.agents_to_notify(rdv, rdv.agents).each do |agent|
      Agents::RdvMailer.with(participation:, agent:).participation_created.deliver_later
    end
  end
end

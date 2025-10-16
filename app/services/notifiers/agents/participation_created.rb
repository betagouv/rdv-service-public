class Notifiers::Agents::ParticipationCreated < BaseService
  def initialize(participation:, author:)
    @participation = participation
    @author = author # peut-être que c’est toujours author == participation.created_by
  end

  def notify_agents
    Notifiers::AgentsFilter.agents_to_notify(rdv: @participation.rdv, author: @author).each do |agent|
      Agents::RdvMailer.with(participation: @participation, agent:).participation_created.deliver_later
    end
  end
end

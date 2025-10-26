class Agents::SecurityMailer < ApplicationMailer
  def new_webhook_url(webhook_endpoint_id:, notified_agent_id:)
    @webhook_endpoint = WebhookEndpoint.find(webhook_endpoint_id)
    @notified_agent = Agent.find(notified_agent_id)
    @author = Agent.agent_from_whodunnit(@webhook_endpoint.versions.last.whodunnit)

    mail(
      to: @notified_agent.email,
      subject: "Une nouvelle URL de webhook vient d'être ajoutée"
    )
  end

  delegate :domain, to: :@notified_agent

  def default_from
    domain.secretariat_email
  end
end

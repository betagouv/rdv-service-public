class Agents::WebhookMailer < ApplicationMailer
  def new_webhook_url(webhook_endpoint_id:, notified_agent_id:)
    @webhook_endpoint = WebhookEndpoint.find(webhook_endpoint_id)
    @notified_agent = Agent.find(notified_agent_id)
    @author = Agent.agent_from_whodunnit(@webhook_endpoint.versions.last.whodunnit)

    to = @notified_agent.email
    subject = if @notified_agent == @author
                "Vous venez d'ajouter une nouvelle URL de webhook"
              else
                "Une nouvelle URL de webhook vient d'être ajoutée"
              end

    mail(to:, subject:)
  end

  delegate :domain, to: :@notified_agent

  def default_from
    domain.secretariat_email
  end
end

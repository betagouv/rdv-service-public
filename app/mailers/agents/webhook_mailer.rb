class Agents::WebhookMailer < ApplicationMailer
  def new_webhook_url(webhook_endpoint_id:, notified_agent_id:)
    @webhook_endpoint = WebhookEndpoint.find(webhook_endpoint_id)
    @notified_agent = Agent.find(notified_agent_id)
    @whodunnit = @webhook_endpoint.versions.last.whodunnit
    @author = Agent.agent_from_whodunnit(@whodunnit)
    @via_api = @whodunnit&.include?("(via API)")

    to = @notified_agent.email
    subject = if @via_api
                "Un webhook vient d'être ajouté par API"
              elsif @notified_agent == @author
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

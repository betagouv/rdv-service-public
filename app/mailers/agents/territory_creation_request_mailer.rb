class Agents::TerritoryCreationRequestMailer < ApplicationMailer
  def accepted(agent:, domain_id:, organisation:)
    @agent = agent
    @domain = Domain.find(domain_id) # On passe par le domain_id pour éviter les erreurs de sérialisation
    @organisation = organisation
    mail(to: agent.email, subject: t(".title", domain_name: domain))
  end

  private

  attr_reader :domain
end

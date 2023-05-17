# frozen_string_literal: true

class Admins::OrganisationMailer < ApplicationMailer
  def organisation_created(agent, organisation)
    @agent = agent
    @organisation = organisation
    mail(to: domain.support_email, subject: "Nouvelle organisation créée - #{@organisation.departement_number} - #{@organisation.name}")
  end

  def domain
    @agent.domain
  end
end

# frozen_string_literal: true

class Admins::OrganisationMailerPreview < ActionMailer::Preview
  def organisation_created
    agent = Organisation.first.agents.first
    Admins::OrganisationMailer.organisation_created(agent, agent.organisations.first)
  end
end

class Admins::OrganisationMailerPreview < ActionMailer::Preview
  def organisation_created
    agent = Organisation.first.agents.first
    Admins::OrganisationMailer.organisation_created(agent)
  end
end

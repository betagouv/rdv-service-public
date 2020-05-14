class Admins::OrganisationMailerPreview < ActionMailer::Preview
  def new_organisation
    agent = Organisation.first.agents.first
    Admins::OrganisationMailer.new_organisation(agent)
  end
end

class Admins::OrganisationMailer < ApplicationMailer
  def organisation_created(agent)
    @agent = agent
    mail(to: "contact@rdv-solidarites.fr", subject: "Une nouvelle organisation a été créée")
  end
end

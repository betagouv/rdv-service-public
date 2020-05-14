class Admins::OrganisationMailer < ApplicationMailer
  def new_organisation(agent)
    @agent = agent
    mail(to: "contact@rdv-solidarites.fr", subject: "Une nouvelle organisation a été créée")
  end
end

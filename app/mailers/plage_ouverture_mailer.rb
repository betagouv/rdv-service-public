class PlageOuvertureMailer < ApplicationMailer
  def send_ics_to_agent(plage_ouverture)
    # @rdv = rdv
    # @user = user
    # ics = Rdv::Ics.new(rdv: @rdv)
    # attachments[ics.name] = { mime_type: 'text/calendar', content: ics.to_ical_for(user) }
    mail(to: plage_ouverture.agent.email, subject: "Votre planning RDV Solidarités")
  end
end

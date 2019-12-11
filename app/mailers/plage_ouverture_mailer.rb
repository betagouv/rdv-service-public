class PlageOuvertureMailer < ApplicationMailer
  def send_ics_to_agent(plage_ouverture)
    @plage_ouverture = plage_ouverture
    ics = PlageOuverture::Ics.new(plage_ouverture: @plage_ouverture)
    attachments[ics.name] = { mime_type: 'text/calendar', content: ics.to_ical }
    mail(to: plage_ouverture.agent.email, subject: "Votre planning #{BRAND}")
  end
end

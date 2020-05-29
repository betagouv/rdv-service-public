class Agents::PlageOuvertureMailer < ApplicationMailer
  def plage_ouverture_created(plage_ouverture)
    @plage_ouverture = plage_ouverture
    ics = PlageOuverture::Ics.new(plage_ouverture: @plage_ouverture)
    attachments["invite.ics"] = {
      mime_type: 'application/ics',
      content: ics.to_ical,
      encoding: "8bit", # fixes encoding issues in ICS
    }
    m = mail(
      to: plage_ouverture.agent.email,
      subject: "#{BRAND} #{plage_ouverture.title} - Plage d'ouverture"
    )
    m.add_part(
      Mail::Part.new do
        content_type "text/calendar; method=REQUEST"
        body ics.to_ical
        content_transfer_encoding "8bit"
      end
    )
    m
  end
end

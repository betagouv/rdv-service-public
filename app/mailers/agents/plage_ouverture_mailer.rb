class Agents::PlageOuvertureMailer < ApplicationMailer
  def plage_ouverture_created(plage_ouverture)
    @plage_ouverture = plage_ouverture
    ics = PlageOuverture::Ics.new(plage_ouverture: @plage_ouverture)
    attachments["invite.ics"] = {
      mime_type: 'application/ics',
      content: Base64.encode64(ics.to_ical),
      encoding: "base64", # seems necessary for attachments
    }
    m = mail(
      from: 'secretariat-auto@rdv-solidarites.fr',
      to: plage_ouverture.agent.email,
      subject: "#{BRAND} #{plage_ouverture.title} - Plage d'ouverture"
    )
    m.add_part(
      Mail::Part.new do
        content_type "text/calendar; method=REQUEST; charset=utf-8"
        body Base64.encode64(ics.to_ical)
        content_transfer_encoding "base64"
        # quoted-printable would be more adapted but there seems to be an encoding problem with extra =0D
      end
    )
    m
  end
end

class Agents::PlageOuvertureMailer < ApplicationMailer
  def plage_ouverture_created(plage_ouverture)
    send_mail(plage_ouverture, "Plage d'ouverture créée")
  end

  def plage_ouverture_updated(plage_ouverture)
    send_mail(plage_ouverture, "Plage d'ouverture modifiée")
  end

  private

  def send_mail(plage_ouverture, title)
    ics = PlageOuverture::Ics.new(plage_ouverture: plage_ouverture)
    attachments[ics.name] = {
      mime_type: "text/calendar",
      content: ics.to_ical,
      encoding: "8bit", # fixes encoding issues in ICS
    }
    m = mail(
      from: "secretariat-auto@rdv-solidarites.fr",
      to: plage_ouverture.agent.email,
      subject: "#{BRAND} #{plage_ouverture.title} - #{title}"
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

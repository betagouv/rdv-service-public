class Agents::PlageOuvertureMailer < ApplicationMailer
  def plage_ouverture_created(plage_ouverture_payload)
    send_mail(plage_ouverture_payload)
  end

  def plage_ouverture_updated(plage_ouverture_payload)
    send_mail(plage_ouverture_payload)
  end

  def plage_ouverture_destroyed(plage_ouverture_payload)
    send_mail(plage_ouverture_payload)
  end

  private

  def send_mail(plage_ouverture_payload)
    attachments[plage_ouverture_payload[:name]] = {
      mime_type: "text/calendar",
      content: Admin::Ics::PlageOuverture.to_ical(plage_ouverture_payload),
      encoding: "8bit" # fixes encoding issues in ICS
    }

    m = mail(
      from: "secretariat-auto@rdv-solidarites.fr",
      to: plage_ouverture_payload[:agent_email],
      subject: "#{BRAND} - #{plage_ouverture_payload[:title]}"
    )
    m.add_part(
      Mail::Part.new do
        content_type "text/calendar; method=REQUEST; charset=utf-8"
        body Base64.encode64(Admin::Ics::PlageOuverture.to_ical(plage_ouverture_payload))
        content_transfer_encoding "base64"
        # quoted-printable would be more adapted but there seems to be an encoding problem with extra =0D
      end
    )
    m
  end
end

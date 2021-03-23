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

  def debug_ics(ics_path, email, name)
    send_ics(File.read(ics_path), "invite.ics", email, name)
  end

  private

  def send_mail(plage_ouverture_payload)
    send_ics(
      Admin::Ics::PlageOuverture.to_ical(plage_ouverture_payload),
      plage_ouverture_payload[:name],
      plage_ouverture_payload[:agent_email],
      plage_ouverture_payload[:title]
    )
  end

  def send_ics(ics_content, attachment_name, recipient_email, title)
    attachments[attachment_name] = {
      mime_type: "text/calendar",
      content: ics_content,
      encoding: "8bit", # fixes encoding issues in ICS
    }

    m = mail(
      from: "secretariat-auto@rdv-solidarites.fr",
      to: recipient_email,
      subject: "#{BRAND} - #{title}"
    )
    m.add_part(
      Mail::Part.new do
        content_type "text/calendar; method=REQUEST; charset=utf-8"
        body Base64.encode64(ics_content)
        content_transfer_encoding "base64"
        # quoted-printable would be more adapted but there seems to be an encoding problem with extra =0D
      end
    )
    m
  end
end

# frozen_string_literal: true

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
    self.ics_payload = plage_ouverture_payload

    mail(
      from: "secretariat-auto@rdv-solidarites.fr",
      to: plage_ouverture_payload[:agent_email],
      subject: "#{BRAND} - #{plage_ouverture_payload[:title]}"
    )
  end
end

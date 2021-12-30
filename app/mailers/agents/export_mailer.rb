# frozen_string_literal: true

class Agents::ExportMailer < ApplicationMailer
  def rdv_export(agent_email, excel_data)
    now = Time.zone.now
    mail.attachments["export-rdv-#{now.strftime('%Y-%m-%d')}.xls"] = {
      mime_type: "application/vnd.ms-excel",
      content: excel_data
    }

    mail(
      from: "secretariat-auto@rdv-solidarites.fr",
      to: agent_email,
      subject: "Export RDV du #{now.strftime('%d/%m/%Y')}"
    )
  end
end

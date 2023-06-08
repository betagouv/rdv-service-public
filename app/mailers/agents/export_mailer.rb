# frozen_string_literal: true

require "zip"

class Agents::ExportMailer < ApplicationMailer
  def rdv_export(agent, file_name, xls_string)
    @agent = agent
    add_zip_as_attachment(file_name: file_name, file_content: xls_string)

    mail(
      to: agent.email,
      subject: I18n.t("mailers.agents.export_mailer.rdv_export.subject", date: I18n.l(Time.zone.now))
    )
  end

  def rdvs_users_export(agent, file_name, xls_string)
    @agent = agent
    add_zip_as_attachment(file_name: file_name, file_content: xls_string)

    mail(
      to: agent.email,
      subject: I18n.t("mailers.agents.export_mailer.full_rdvs_user_export.subject", date: I18n.l(Time.zone.now))
    )
  end

  def domain
    @agent.domain
  end

  def default_from
    domain.secretariat_email
  end

  private

  def add_zip_as_attachment(file_name:, file_content:)
    zip_file = Zip::OutputStream.write_buffer do |zos|
      zos.put_next_entry(file_name)
      zos.write file_content
    end

    mail.attachments["#{file_name}.zip"] = {
      mime_type: "application/zip",
      content: zip_file.string,
    }
  end
end

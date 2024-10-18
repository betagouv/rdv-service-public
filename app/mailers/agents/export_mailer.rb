require "zip"

class Agents::ExportMailer < ApplicationMailer
  def rdv_export(export_id)
    @export = Export.find(export_id)

    mail(
      to: @export.agent.email,
      subject: I18n.t("mailers.agents.export_mailer.rdv_export.subject", date: I18n.l(Time.zone.now, format: :dense))
    )
  end

  def participations_export(export_id)
    @export = Export.find(export_id)

    mail(
      to: @export.agent.email,
      subject: I18n.t("mailers.agents.export_mailer.full_participation_export.subject", date: I18n.l(Time.zone.now, format: :dense))
    )
  end

  def domain
    @export.agent.domain
  end

  def default_from
    domain.secretariat_email
  end
end

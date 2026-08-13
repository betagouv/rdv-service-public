class Agents::ExportMailer < ApplicationMailer
  def export_ready(export_id)
    @export = Export.find(export_id)

    date = I18n.l(Time.zone.now, format: :dense)
    subject = {
      Export::RDV_EXPORT => "Export des RDVs du #{date}",
      Export::PARTICIPATIONS_EXPORT => "Export des RDVs par usager du #{date}",
    }.fetch(@export.export_type.to_s)

    mail(to: @export.agent.email, subject:)
  end

  def domain
    @export.agent.domain
  end

  def default_from
    domain.secretariat_email
  end
end

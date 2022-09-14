# frozen_string_literal: true

class Agents::ExportMailer < ApplicationMailer
  def rdv_export(agent, organisation, options)
    @agent = agent
    now = Time.zone.now
    rdvs = Rdv.search_for(agent, organisation, options)

    mail.attachments["export-rdv-org-#{organisation.id}-#{now.strftime('%Y-%m-%d')}.xls"] = {
      mime_type: "application/vnd.ms-excel",
      content: RdvExporter.export(rdvs.order(starts_at: :desc)),
    }

    mail(
      to: agent.email,
      subject: I18n.t("mailers.agents.export_mailer.rdv_export.subject", organisation_name: organisation.name, date: I18n.l(now))
    )
  end

  def domain
    @agent.domain
  end

  def default_from
    SECRETARIAT_EMAIL
  end
end

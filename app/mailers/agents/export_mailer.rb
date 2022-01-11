# frozen_string_literal: true

class Agents::ExportMailer < ApplicationMailer
  def rdv_export(agent_id, organisation_id, options)
    now = Time.zone.now
    agent = Agent.find(agent_id)
    organisation = Organisation.find(organisation_id)
    rdvs = Rdv.search_for(agent, organisation, options)

    mail.attachments["export-rdv-#{now.strftime('%Y-%m-%d')}.xls"] = {
      mime_type: "application/vnd.ms-excel",
      content: RdvExporter.export(rdvs.order(starts_at: :desc))
    }

    mail(
      from: "secretariat-auto@rdv-solidarites.fr",
      to: agent.email,
      subject: I18n.t("mailers.agents.export_mailer.rdv_export.subject", organisation_name: organisation.name, date: I18n.l(now))
    )
  end
end

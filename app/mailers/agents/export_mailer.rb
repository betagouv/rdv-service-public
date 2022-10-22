# frozen_string_literal: true

class Agents::ExportMailer < ApplicationMailer
  def rdv_export(agent, organisation, options)
    @agent = agent
    now = Time.zone.now
    rdvs = Rdv.search_for(organisation, options)

    # Le département du Var se base sur la position de chaque caractère du nom
    # de fichier pour extraire la date et l'ID d'organisation, donc
    # si on modifie le fichier il faut soit les prévenir soit ajouter à la fin.
    file_name = "export-rdv-#{now.strftime('%Y-%m-%d')}-org-#{organisation.id.to_s.rjust(6, '0')}.xls"
    mail.attachments[file_name] = {
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

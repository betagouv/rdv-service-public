# frozen_string_literal: true

class Agents::ExportMailer < ApplicationMailer
  def rdv_export(agent, organisation_ids, options)
    raise "Agent does not belong to all requested organisation(s)" if (organisation_ids - agent.organisation_ids).any?

    @agent = agent
    now = Time.zone.now
    organisations = agent.organisations.where(id: organisation_ids)
    rdvs = Rdv.search_for(organisations, options)

    # Le département du Var se base sur la position de chaque caractère du nom
    # de fichier pour extraire la date et l'ID d'organisation, donc
    # si on modifie le fichier il faut soit les prévenir soit ajouter à la fin.
    file_name = if organisations.count == 1
                  "export-rdv-#{now.strftime('%Y-%m-%d')}-org-#{organisations.first.id.to_s.rjust(6, '0')}.xls"
                else
                  "export-rdv-#{now.strftime('%Y-%m-%d')}.xls"
                end
    mail.attachments[file_name] = {
      mime_type: "application/vnd.ms-excel",
      content: RdvExporter.export(rdvs.order(starts_at: :desc)),
    }

    mail(
      to: agent.email,
      subject: I18n.t("mailers.agents.export_mailer.rdv_export.subject", date: I18n.l(now))
    )
  end

  def rdvs_users_export(agent, organisation_ids, options)
    raise "Agent does not belong to all requested organisation(s)" if (organisation_ids - agent.organisation_ids).any?

    @agent = agent
    now = Time.zone.now
    organisations = agent.organisations.where(id: organisation_ids)

    rdvs = Rdv.search_for(organisations, options)
    rdvs_users = RdvsUser.where(rdv_id: rdvs.select(:id))

    file_name = "export-rdvs-user-#{now.strftime('%Y-%m-%d')}.xls"
    mail.attachments[file_name] = {
      mime_type: "application/vnd.ms-excel",
      content: RdvsUserExporter.export(rdvs_users.order(id: :desc)),
    }

    mail(
      to: agent.email,
      subject: I18n.t("mailers.agents.export_mailer.full_rdvs_user_export.subject", date: I18n.l(now))
    )
  end

  def domain
    @agent.domain
  end

  def default_from
    SECRETARIAT_EMAIL
  end
end

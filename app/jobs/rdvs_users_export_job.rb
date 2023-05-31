# frozen_string_literal: true

class RdvsUsersExportJob < ExportJob
  def perform(agent:, organisation_ids:, options:)
    raise "Agent does not belong to all requested organisation(s)" if (organisation_ids - agent.organisation_ids).any?

    @agent = agent
    now = Time.zone.now
    organisations = agent.organisations.where(id: organisation_ids)

    rdvs = Rdv.search_for(organisations, options)
    rdvs_users = RdvsUser.where(rdv_id: rdvs.select(:id))

    file_name = "export-rdvs-user-#{now.strftime('%Y-%m-%d')}.xls"
    xls_string = RdvsUserExporter.export(rdvs_users.order(id: :desc))

    # Using #deliver_now because we don't want to enqueue a job with a huge payload
    Agents::ExportMailer.rdvs_users_export(agent, file_name, xls_string).deliver_now
  end
end

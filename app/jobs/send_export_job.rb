# frozen_string_literal: true

class SendExportJob < ApplicationJob
  queue_as :send_export

  def perform(agent_id, organisation_id, options)
    agent = Agent.find(agent_id)
    organisation = Organisation.find(organisation_id)

    rdvs = Rdv.search_for(agent, organisation, options)
    data = RdvExporter.export(rdvs.order(starts_at: :desc))
    Agents::ExportMailer.rdv_export(agent.email, data).deliver_later
  end
end

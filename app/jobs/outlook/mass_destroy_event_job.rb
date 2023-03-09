# frozen_string_literal: true

module Outlook
  class MassDestroyEventJob < ApplicationJob
    queue_as :outlook_sync

    def perform(agent)
      client = Outlook::ApiClient.new(agent)
      agent.agents_rdvs.where.not(outlook_id: nil).each do |agents_rdv|
        client.delete_event!(agents_rdv.outlook_id)
      end
      agent.update!(microsoft_graph_token: nil, refresh_microsoft_graph_token: nil, outlook_disconnect_in_progress: false)
    end
  end
end

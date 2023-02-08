# frozen_string_literal: true

module Outlook
  class MassDestroyEventJob < ApplicationJob
    queue_as :outlook_sync

    def perform(agent)
      agent.agents_rdvs.exists_in_outlook.each do |agents_rdv|
        Outlook::DestroyEventJob.perform_now(agents_rdv.outlook_id, agents_rdv.agent)
      end
      agent.update!(microsoft_graph_token: nil, refresh_microsoft_graph_token: nil)
    end
  end
end

module Outlook
  class MassCreateEventJob < ApplicationJob
    include ExtendedRetryStrategyConcern

    def perform(agent)
      Sentry.set_user({ id: agent.id, role: "Agent", email: agent.email })

      agent.agents_rdvs.joins(:rdv).where(rdv: { starts_at: 1.month.ago.. }).find_each do |agents_rdv|
        Outlook::SyncEventJob.perform_later_for(agents_rdv, queue: :latency_5m)
      end
    end
  end
end

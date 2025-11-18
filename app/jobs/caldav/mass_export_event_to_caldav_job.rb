module Caldav
  class MassExportEventToCaldavJob < ApplicationJob
    include ExtendedRetryStrategyConcern

    def perform(agent)
      Sentry.set_user({ id: agent.id, role: "Agent", email: agent.email })

      return unless agent.caldav_configured?

      agent.agents_rdvs.joins(:rdv).where(rdv: { starts_at: Time.zone.today.. }).find_each do |agents_rdv|
        Caldav::ExportEventToCaldavJob.perform_later(agents_rdv.id, agent.id)
      end
    end
  end
end

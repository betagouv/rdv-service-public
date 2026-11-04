module Caldav
  class MassExportEventToCaldavJob < Caldav::BaseJob
    include ExtendedRetryStrategyConcern

    def perform(agent)
      Sentry.set_user({ id: agent.id, role: "Agent", email: agent.email })

      return unless agent.caldav_configured?

      agent.agents_rdvs.joins(:rdv).where(rdv: { starts_at: 2.weeks.ago.. }).find_each do |agents_rdv|
        Caldav::ExportRdvToCaldavJob.perform_later(agents_rdv.id, agent.id)
      end
    end
  end
end

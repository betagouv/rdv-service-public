module Caldav
  class MassCreateEventJob < ApplicationJob
    include ExtendedRetryStrategyConcern

    def perform(agent)
      Sentry.set_user({ id: agent.id, role: "Agent", email: agent.email })

      return unless agent.caldav_configured?

      agent.agents_rdvs.joins(:rdv).where(rdv: { starts_at: Time.zone.today.. }).find_each do |agents_rdv|
        Caldav::SyncEventJob.perform_later(agents_rdv.id)
      end
    end

    private

    def caldav_client
      @caldav_client ||= Calendav::Client.new(
        Calendav::Credentials::Standard.new(
          host: agents_rdv.agent.caldav_agenda_url,
          username: agents_rdv.agent.caldav_username,
          password: agents_rdv.agent.caldav_password,
          authentication: :basic_auth
        )
      )
    end
  end
end

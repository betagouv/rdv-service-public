module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_agent
    rescue_from(StandardError) { Sentry.capture_exception(_1) }

    def connect
      self.current_agent = find_verified_agent
    end

    private

    def find_verified_agent
      session = cookies.encrypted[Rails.application.config.session_options[:key]]

      if session
        agent_id_from_session = session["warden.user.agent.key"].first.first
        Agent.find_by(id: agent_id_from_session) || reject_unauthorized_connection
      else
        # On est dans ce cas lorsqu'un agent laisse son navigateur ouvert
        # toute la nuit et que le cookie a expiré le lendemain.
        reject_unauthorized_connection
      end
    end
  end
end

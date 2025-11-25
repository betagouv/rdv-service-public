module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_agent
    rescue_from StandardError, with: :report_error

    def connect
      self.current_agent = find_verified_agent
    end

    private

    def find_verified_agent
      session = cookies.encrypted[Rails.application.config.session_options[:key]]
      agent_id_from_session = session["warden.user.agent.key"].first.first
      Agent.find_by(id: agent_id_from_session) || reject_unauthorized_connection
    end

    def report_error(e)
      Sentry.capture_exception(e)
    end
  end
end

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_agent
    rescue_from(StandardError) { Sentry.capture_exception(_1) }

    def connect
      self.current_agent = find_verified_agent
    end

    private

    def find_verified_agent
      # La valeur de `session_options` est définie via `config.session_store`
      session = cookies.encrypted[Rails.application.config.session_options[:key]]

      # NOTE : Le cookie de session peut être manquant ici, notamment si l'agent laisse son
      # navigateur ouvert toute la nuit et que le cookie de session a expiré le lendemain.
      agent_id_from_session = session["warden.user.agent.key"]&.first&.first.presence if session

      if session && agent_id_from_session.nil?
        # Débugging temporaire : on a un cookie de session, mais pas d'agent_id, on veut en savoir plus !
        Redis.with_connection { _1.lpush("action_cable_connection_debug", session.to_json) }
      end

      if agent_id_from_session
        agent = Agent.find_by(id: agent_id_from_session)
        return agent if agent.present?
      end

      reject_unauthorized_connection
    end
  end
end

# Ne doit jamais ralentir la ProConnexion : exécuté en asynchrone après la connexion de l'agent.
class MenshenExchangeTokenJob < ApplicationJob
  # L'access token ProConnect ne doit pas fuiter dans les logs/Sentry
  self.log_arguments = false

  discard_on(ActiveRecord::RecordNotFound) { |_job, error| Sentry.capture_exception(error) }

  def perform(agent_id, subject_token)
    agent = Agent.find(agent_id)
    response = Menshen::ExchangeToken.new(subject_token:).call

    agent.update!(
      menshen_access_token: response["access_token"],
      menshen_access_token_expires_at: response["expires_in"].seconds.from_now
    )
  end
end

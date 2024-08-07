AgentConnect.initialize! do |config|
  config.client_id = ENV["AGENT_CONNECT_CLIENT_ID"]
  config.client_secret = ENV["AGENT_CONNECT_CLIENT_SECRET"]
  config.scope = "openid email given_name usual_name"
  config.base_url = ENV["AGENT_CONNECT_BASE_URL"]
  config.algorithm = "ES256"

  config.success_callback = lambda do |callback_client|
    include DomainDetection
    include Pundit::Authorization

    # Agent Connect recommande de faire la réconciliation sur l'email et non pas sur le sub
    # voir https://github.com/numerique-gouv/agentconnect-documentation/blob/main/doc_fs/donnees_fournies.md#le-champ-sub
    agent = Agent.active.find_by(email: callback_client.user_email)

    if agent
      agent.update!(
        connected_with_agent_connect: true,
        first_name: callback_client.user_first_name,
        last_name: callback_client.user_last_name,
        invitation_token: nil, # Pour désactiver les anciens liens d'invitation
        invitation_accepted_at: agent.invitation_accepted_at || Time.zone.now,
        confirmed_at: agent.confirmed_at || Time.zone.now,
        last_sign_in_at: Time.zone.now
      )

      bypass_sign_in agent, scope: :agent
      session[:agent_connect_id_token] = callback_client.id_token_for_logout
      redirect_to root_path
    else
      flash[:error] = "Il n'y a pas de compte agent pour l'adresse mail #{callback_client.user_email}.<br />" \
                      "Vous devez utiliser Agent Connect avec l'adresse mail à laquelle vous avez reçu votre invitation sur #{current_domain.name}.<br />" \
                      "Vous pouvez également contacter le support à l'adresse <a href='mailto:#{current_domain.support_email}'>#{current_domain.support_email}</a> si le problème persiste."
      redirect_to Rails.application.routes.url_helpers.new_agent_session_path
    end
  end

  config.error_callback = lambda do |_|
    flash[:error] = "Nous n'avons pas pu vous connecter. Veuillez réessayer."
    redirect_to Rails.application.routes.url_helpers.new_agent_session_path
  end

  config.bootstrap_error_callback = lambda do |_|
    ENV["AGENT_CONNECT_DISABLED"] = "true"
  end
end

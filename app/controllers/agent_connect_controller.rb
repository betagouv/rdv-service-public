class AgentConnectController < ApplicationController
  before_action :log_params_to_sentry

  def auth
    auth_client = AgentConnectOpenIdClient::Auth.new(login_hint: params[:login_hint])
    session[:agent_connect_state] = auth_client.state
    session[:nonce] = auth_client.nonce

    redirect_to auth_client.redirect_url(agent_connect_callback_url), allow_other_host: true
  end

  def callback
    callback_client = AgentConnectOpenIdClient::Callback.new(
      session_state: session.delete(:agent_connect_state),
      params_state: params[:state],
      callback_url: agent_connect_callback_url,
      nonce: session.delete(:nonce)
    )

    unless callback_client.fetch_user_info_from_code!(params[:code])
      flash[:error] = generic_error_message
      redirect_to(new_agent_session_path) and return
    end

    # Agent Connect recommande de faire la réconciliation sur l'email et non pas sur le sub
    # voir https://github.com/france-connect/Documentation-AgentConnect/blob/main/doc_fs/projet_fca/projet_fca_donnees.md
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
      # On pourrait améliorer le cas d'erreur décrit dans https://github.com/betagouv/rdv-service-public/issues/4360
      # voir la branche `agent-connect-prompt-login`
      flash[:error] = "Il n'y a pas de compte agent pour l'adresse mail #{callback_client.user_email}.<br />" \
                      "Vous devez utiliser Agent Connect avec l'adresse mail à laquelle vous avez reçu votre invitation sur #{current_domain.name}.<br />" \
                      "Vous pouvez également contacter le support à l'adresse <a href='mailto:#{current_domain.support_email}'>#{current_domain.support_email}</a> si le problème persiste."
      redirect_to new_agent_session_path
    end
  end

  private

  def generic_error_message
    support_email = current_domain.support_email
    %(Nous n'avons pas pu vous authentifier. Contactez le support à l'adresse <a href="mailto:#{support_email}">#{support_email}</a> si le problème persiste.)
  end
end

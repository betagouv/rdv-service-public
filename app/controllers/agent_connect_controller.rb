class AgentConnectController < ApplicationController
  before_action :log_params_to_sentry

  def auth
    state = Digest::SHA1.hexdigest("Agent Connect - #{SecureRandom.base58(16)}")
    session[:agent_connect_state] = state
    nonce = SecureRandom.base58(32)
    session[:nonce] = nonce
    query_params = {
      response_type: "code",
      client_id: AgentConnect::AGENT_CONNECT_CLIENT_ID,
      redirect_uri: agent_connect_callback_url,
      scope: "openid email given_name usual_name",
      state: state,
      nonce: nonce,
      acr_values: "eidas1",
      login_hint: params[:login_hint],
    }.compact_blank

    agent_connect_redirect_url = "#{AgentConnect::AGENT_CONNECT_BASE_URL}/authorize?#{query_params.to_query}"

    redirect_to agent_connect_redirect_url, allow_other_host: true
  end

  def callback
    # TODO: check nonce
    agent_connect_state = session.delete(:agent_connect_state)
    if agent_connect_state.blank? || params[:state] != agent_connect_state
      Sentry.capture_message(
        "Agent Connect states in session and params do not match",
        extra: { params_state: params[:state], session_agent_connect_state: agent_connect_state },
        fingerprint: ["agent_connect_state_mismatch"]
      )
      flash[:error] = error_message
      redirect_to(new_agent_session_path) and return
    end

    agent = AgentConnect.new.authenticate_and_find_agent(params[:code], agent_connect_callback_url)

    if agent
      bypass_sign_in agent, scope: :agent
      redirect_to root_path
    else
      flash[:error] = error_message
      Sentry.capture_message("Failed to authenticate agent with Agent Connect", fingerprint: ["agent_connect_other_error"])
      redirect_to new_agent_session_path
    end
  rescue AgentConnect::AgentNotFoundError => e
    flash[:error] = "Il n'y a pas de compte agent pour l'adresse mail #{e.message}.<br />" \
                    "Vous devez utiliser Agent Connect avec l'adresse mail à laquelle vous avez reçu votre invitation sur #{current_domain.name}.<br />" \
                    "Vous pouvez également contacter le support à l'adresse <a href='mailto:#{current_domain.support_email}'>#{current_domain.support_email}</a> si le problème persiste."
    Sentry.capture_message("Failed to authenticate agent with Agent Connect - Agent not found", extra: { exception_message: e.message }, fingerprint: ["agent_connect_agent_not_found"])
    redirect_to new_agent_session_path
  rescue AgentConnect::ApiRequestError => e
    flash[:error] = error_message
    Sentry.capture_message("Failed to authenticate agent with Agent Connect - Api error", extra: { exception_message: e.message }, fingerprint: ["agent_connect_api_error"])
    redirect_to new_agent_session_path
  end

  private

  def error_message
    email = current_domain.support_email
    %(Nous n'avons pas pu vous authentifier. Contactez le support à l'adresse <a href="mailto:#{email}">#{email}</a> si le problème persiste.)
  end
end

class AgentConnectController < ApplicationController
  before_action :log_params_to_sentry

  def auth
    state = Digest::SHA1.hexdigest("Agent Connect - #{SecureRandom.base58(16)}")
    session[:agent_connect_state] = state
    query_params = {
      response_type: "code",
      client_id: AgentConnect::AGENT_CONNECT_CLIENT_ID,
      redirect_uri: agent_connect_callback_url,
      scope: "openid email profile",
      state: state,
      from: "community",
      login_hint: params[:login_hint],
    }.compact_blank

    agent_connect_redirect_url = "#{AgentConnect::AGENT_CONNECT_BASE_URL}/api/v2/authorize/?#{query_params.to_query}"

    redirect_to agent_connect_redirect_url, allow_other_host: true
  end

  def callback
    agent_connect_state = session.delete(:agent_connect_state)
    if agent_connect_state.blank? || params[:state] != agent_connect_state
      Sentry.capture_message("Agent Connect states is session and params do not match", extra: { params_state: params[:state], session_ic_state: agent_connect_state },
                                                                                        fingerprint: ["agent_connect_state_mismatch"])
      flash[:error] = error_message
      redirect_to new_agent_session_path and return
    end

    agent = AgentConnect.new(params[:code], agent_connect_callback_url).authenticate_and_find_agent

    if agent
      bypass_sign_in agent, scope: :agent
      redirect_to root_path
    else
      flash[:error] = error_message
      Sentry.capture_message("Failed to authenticate agent with InclusionConnect", fingerprint: ["ic_other_error"])
      redirect_to new_agent_session_path
    end
  rescue InclusionConnect::AgentNotFoundError => e
    flash[:error] = "Il n'y a pas de compte agent pour l'adresse mail #{e.message}.<br />" \
                    "Vous devez utiliser Inclusion Connect avec l'adresse mail à laquelle vous avez reçu votre invitation sur #{current_domain.name}.<br />" \
                    "Vous pouvez également contacter le support à l'adresse <a href='mailto:#{current_domain.support_email}'>#{current_domain.support_email}</a> si le problème persiste."
    Sentry.capture_message("Failed to authenticate agent with InclusionConnect - Agent not found", extra: { exception_message: e.message }, fingerprint: ["ic_agent_not_found"])
    redirect_to new_agent_session_path
  rescue InclusionConnect::ApiRequestError => e
    flash[:error] = error_message
    Sentry.capture_message("Failed to authenticate agent with InclusionConnect - Api error", extra: { exception_message: e.message }, fingerprint: ["ic_api_error"])
    redirect_to new_agent_session_path
  end

  private

  def error_message
    email = current_domain.support_email
    %(Nous n'avons pas pu vous authentifier. Contactez le support à l'adresse <a href="mailto:#{email}">#{email}</a> si le problème persiste.)
  end
end

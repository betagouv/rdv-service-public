class InclusionConnectController < ApplicationController
  before_action :log_params_to_sentry

  def auth
    session[:ic_state] = Digest::SHA1.hexdigest("InclusionConnect - #{SecureRandom.hex(13)}")
    redirect_to InclusionConnect.auth_path(session[:ic_state], inclusion_connect_callback_url, login_hint: params[:login_hint]), allow_other_host: true
  end

  def callback
    ic_state = session.delete(:ic_state)
    if ic_state.blank? || params[:state] != ic_state
      Sentry.capture_message("InclusionConnect states do not match", extra: { params_state: params[:state], session_ic_state: ic_state }, fingerprint: ["ic_state_mismatch"])
      flash[:error] = error_message
      redirect_to new_agent_session_path and return
    end

    agent = InclusionConnect.new.authenticate_and_find_agent(params[:code], inclusion_connect_callback_url)

    if agent
      bypass_sign_in agent, scope: :agent
      redirect_to root_path
    else
      flash[:error] = error_message
      Sentry.capture_message("Failed to authenticate agent with InclusionConnect", fingerprint: ["ic_agent_not_found"])
      redirect_to new_agent_session_path
    end
  end

  private

  def error_message
    email = current_domain.support_email
    %(Nous n'avons pas pu vous authentifier. Contactez le support à l'adresse <a href="mailto:#{email}">#{email}</a> si le problème persiste.)
  end
end

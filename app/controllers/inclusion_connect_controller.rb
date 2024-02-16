class InclusionConnectController < ApplicationController
  before_action :log_params_to_sentry

  def auth
    session[:ic_state] = Digest::SHA1.hexdigest("InclusionConnect - #{SecureRandom.hex(13)}")
    redirect_to InclusionConnect.auth_path(session[:ic_state], inclusion_connect_callback_url), allow_other_host: true
  end

  def callback
    ic_state = session.delete(:ic_state)
    if ic_state.blank? || params[:state] != ic_state
      Sentry.capture_message("InclusionConnect states do not match", extra: { params_state: params[:state], session_ic_state: ic_state })
      flash[:error] = "Nous n'avons pas pu vous authentifier. Contacter le support à l'adresse <#{current_domain.support_email}> si le problème persiste."
      redirect_to new_agent_session_path and return
    end

    agent = InclusionConnect.authenticate_and_find_agent(params[:code], inclusion_connect_callback_url)

    if agent
      bypass_sign_in agent, scope: :agent
      redirect_to root_path
    else
      flash[:error] = "Nous n'avons pas pu vous authentifier. Contacter le support à l'adresse <#{current_domain.support_email}> si le problème persiste."
      Sentry.capture_message("Failed to authentify agent with inclusionConnect")
      redirect_to new_agent_session_path
    end
  end
end

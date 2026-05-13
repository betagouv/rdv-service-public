class Agents::SessionsByCodeController < ApplicationController
  SESSION_AGENT_ID_KEY = :pending_agent_login_id
  SESSION_PRO_CONNECT_ID_TOKEN_KEY = :pending_pro_connect_id_token

  before_action :require_pending_agent_login

  def new
    @email = pending_agent.email
    @existing_login_code = LoginCode.most_recent_usable_for(email: @email)
  end

  def resend
    Agents::LoginCodeSender.perform(email: pending_agent.email, domain_id: current_domain.id)
    redirect_to new_agents_sessions_by_code_path
  end

  def create
    agent = pending_agent
    code = params.require(:login_code).expect(:code)
    validator = LoginCodeValidator.new(email: agent.email, code:)

    if validator.valid?
      validator.valid_login_code.update!(used_at: Time.zone.now)
      session.delete(SESSION_AGENT_ID_KEY)
      if session[SESSION_PRO_CONNECT_ID_TOKEN_KEY]
        session[:pro_connect_id_token] = session.delete(SESSION_PRO_CONNECT_ID_TOKEN_KEY)
      end
      bypass_sign_in(agent, scope: :agent)
      redirect_to after_sign_in_path_for(agent), flash: { success: "Connexion réussie" }
    else
      @email = agent.email
      @existing_login_code = LoginCode.most_recent_usable_for(email: @email)
      @existing_login_code&.errors&.add(:base, validator.error)
      render :new
    end
  end

  private

  def require_pending_agent_login
    redirect_to new_agent_session_path unless session[SESSION_AGENT_ID_KEY]
  end

  def pending_agent
    @pending_agent ||= Agent.find(session[SESSION_AGENT_ID_KEY])
  end

  def storable_location?
    false
  end
end

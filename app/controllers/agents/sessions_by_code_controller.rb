class Agents::SessionsByCodeController < ApplicationController
  include Agents::LoginCodeVerificationConcern

  SESSION_AGENT_ID_KEY = :pending_agent_login_id
  SESSION_PRO_CONNECT_ID_TOKEN_KEY = :pending_pro_connect_id_token

  before_action :require_pending_agent_login

  def new
    @email = pending_agent.email
    @existing_login_code = LoginCode.most_recent_usable_for(email: @email)
  end

  def resend
    resend_login_code!(pending_agent.email)
    redirect_to new_agents_sessions_by_code_path
  end

  def create
    agent = pending_agent
    submit_login_code!(agent.email) do
      session.delete(SESSION_AGENT_ID_KEY)
      if session[SESSION_PRO_CONNECT_ID_TOKEN_KEY]
        session[:pro_connect_id_token] = session.delete(SESSION_PRO_CONNECT_ID_TOKEN_KEY)
      end
      AgentTrustedDevice.remember_by_cookie!(agent, cookies) if ActiveModel::Type::Boolean.new.cast(params[:remember_device])
      sign_in(agent, scope: :agent)
      redirect_to after_sign_in_path_for(agent)
    end
  end

  private

  def require_pending_agent_login
    redirect_to new_agent_session_path unless session[SESSION_AGENT_ID_KEY]
  end

  def pending_agent
    @pending_agent ||= Agent.find(session[SESSION_AGENT_ID_KEY])
  end

  # Hook Devise — empêche que cette page intermédiaire soit mémorisée comme destination après connexion
  def storable_location?
    false
  end
end

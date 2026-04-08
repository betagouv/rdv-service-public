class Agents::SessionsByCodeController < ApplicationController
  before_action :require_pending_agent_login

  def new
    @email = pending_agent.email
    @existing_login_code = LoginCode.most_recent_usable_for(email: @email)

    unless @existing_login_code&.very_recent?
      @existing_login_code = LoginCode.create!(email: @email, domain_id: current_domain.id)
      Agents::LoginCodeMailer.with(login_code: @existing_login_code).login_code.deliver_later
    end
  end

  def create
    agent = pending_agent
    code = params.require(:login_code).expect(:code)
    validator = Users::LoginCodeValidator.new(email: agent.email, code:)

    if validator.valid?
      validator.valid_login_code.update!(used_at: Time.zone.now)
      session.delete(:pending_agent_login_id)
      if session[:pending_pro_connect_id_token]
        session[:pro_connect_id_token] = session.delete(:pending_pro_connect_id_token)
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
    redirect_to new_agent_session_path unless session[:pending_agent_login_id]
  end

  def pending_agent
    @pending_agent ||= Agent.find(session[:pending_agent_login_id])
  end

  def storable_location?
    false
  end
end

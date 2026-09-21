class Agents::TwoFactorVerificationsController < ApplicationController
  include Agents::TwoFactorFreshnessConcern
  include Agents::LoginCodeVerificationConcern

  before_action :authenticate_agent!

  def new
    if current_agent.pro_connect_2fa_active?
      redirect_to_pro_connect_step_up
    else
      Agents::LoginCodeSender.perform(email: current_agent.email, domain_id: current_domain.id)
      @email = current_agent.email
      @existing_login_code = LoginCode.most_recent_usable_for(email: @email)
    end
  end

  def resend
    resend_login_code!(current_agent.email)
    redirect_to new_agents_two_factor_verification_path
  end

  def create
    submit_login_code!(current_agent.email) do
      mark_two_factor_verified!
      redirect_after_two_factor_verification!(session.delete(RETURN_TO_SESSION_KEY))
    end
  end

  private

  def redirect_to_pro_connect_step_up
    auth_client = ProConnectOpenIdClient::Auth.new(
      login_hint: current_agent.email,
      client_id: current_domain.pro_connect_client_id,
      client_secret: current_domain.pro_connect_client_secret
    )
    session[:pro_connect] = { state: auth_client.state, nonce: auth_client.nonce, connection_for: "agent_step_up" }
    redirect_to auth_client.redirect_url(pro_connect_callback_url, force_2fa: true), allow_other_host: true
  end

  # Hook Devise — empêche que cette page intermédiaire soit mémorisée comme destination après connexion
  def storable_location?
    false
  end
end

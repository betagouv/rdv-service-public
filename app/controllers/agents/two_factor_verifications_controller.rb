class Agents::TwoFactorVerificationsController < ApplicationController
  SUCCESS_NOTICE = "Votre identité a été vérifiée, vous pouvez maintenant continuer votre action.".freeze

  before_action :authenticate_agent!

  def new; end

  def create
    if current_agent.pro_connect_2fa_active?
      redirect_to_pro_connect_step_up
    else
      Agents::LoginCodeSender.perform(email: current_agent.email, domain_id: current_domain.id)
      redirect_to code_agents_two_factor_verification_path
    end
  end

  def code
    @email = current_agent.email
    @existing_login_code = LoginCode.most_recent_usable_for(email: @email)

    # Le code n'est envoyé qu'après confirmation explicite de l'agent sur la page d'explication
    redirect_to new_agents_two_factor_verification_path unless @existing_login_code
  end

  def resend
    Agents::LoginCodeForm.resend_login_code!(current_agent.email, current_domain)
    redirect_to code_agents_two_factor_verification_path
  end

  def verify
    @login_code_form = Agents::LoginCodeForm.new(email: current_agent.email, code: params.require(:login_code).expect(:code))

    if @login_code_form.submit!
      AgentTwoFactorSessionState.mark_verified!(session)
      redirect_to AgentTwoFactorSessionState.pop_return_to!(session), flash: { success: SUCCESS_NOTICE }
    else
      @email = @login_code_form.email
      @existing_login_code = @login_code_form.existing_login_code

      render :code
    end
  end

  private

  def redirect_to_pro_connect_step_up
    auth_client = ProConnectOpenIdClient::Auth.new(
      login_hint: current_agent.email,
      client_id: current_domain.pro_connect_client_id,
      client_secret: current_domain.pro_connect_client_secret
    )
    session[:pro_connect] = { state: auth_client.state, nonce: auth_client.nonce, connection_for: "agent_verify_2fa" }
    redirect_to auth_client.redirect_url(pro_connect_callback_url, force_2fa: true), allow_other_host: true
  end

  # Hook Devise — empêche que cette page intermédiaire soit mémorisée comme destination après connexion
  def storable_location?
    false
  end
end

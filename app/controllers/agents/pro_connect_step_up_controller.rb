class Agents::ProConnectStepUpController < ApplicationController
  SESSION_LOGIN_HINT_KEY = :agent_step_up_login_hint
  SESSION_REMEMBER_DEVICE_KEY = :agent_step_up_remember_device

  before_action :require_pending_step_up

  def new; end

  def create
    session[SESSION_REMEMBER_DEVICE_KEY] = ActiveModel::Type::Boolean.new.cast(params[:remember_device])

    auth_client = ProConnectOpenIdClient::Auth.new(
      login_hint: session[SESSION_LOGIN_HINT_KEY],
      client_id: current_domain.pro_connect_client_id,
      client_secret: current_domain.pro_connect_client_secret
    )

    session[:pro_connect] = {
      state: auth_client.state,
      nonce: auth_client.nonce,
      connection_for: "agent",
    }

    redirect_to auth_client.redirect_url(pro_connect_callback_url, force_2fa: true), allow_other_host: true
  end

  private

  def require_pending_step_up
    redirect_to new_agent_session_path unless session[SESSION_LOGIN_HINT_KEY]
  end

  # Hook Devise — empêche que cette page intermédiaire soit mémorisée comme destination après connexion
  def storable_location?
    false
  end
end

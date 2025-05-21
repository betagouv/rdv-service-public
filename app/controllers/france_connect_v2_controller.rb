class FranceConnectV2Controller < ApplicationController
  STATE_SESSION_KEY = "france_connect_v2_state".freeze
  NONCE_SESSION_KEY = "france_connect_v2_nonce".freeze

  def auth
    auth_client = FranceConnectV2OpenIdClient::Auth.new(
      client_id: ENV["FRANCECONNECT_V2_CLIENT_ID"]
    )
    session[STATE_SESSION_KEY] = auth_client.state
    session[NONCE_SESSION_KEY] = auth_client.nonce

    # J'utilise l'URL de démo ici le temps d'avoir un bac à sable compatible localhost
    redirect_to auth_client.redirect_url("https://demo.rdv.numerique.gouv.fr/omniauth/franceconnect_v2/callback"), allow_other_host: true
  end

  def callback
    state = session[STATE_SESSION_KEY]
    nonce = session[NONCE_SESSION_KEY]
    callback_client = FranceConnectV2OpenIdClient::Callback.new(
      session_state: state,
      params_state: params[:state],
      callback_url: "https://demo.rdv.numerique.gouv.fr/omniauth/franceconnect_v2/callback", # J'utilise l'URL de démo ici le temps d'avoir un bac à sable compatible localhost
      nonce: nonce,
      client_id: ENV["FRANCECONNECT_V2_CLIENT_ID"],
      client_secret: ENV["FRANCECONNECT_V2_CLIENT_SECRET"]
    )

    unless callback_client.fetch_user_info_from_code!(params[:code])
      flash[:error] = generic_error_message
      redirect_to(new_agent_session_path) and return
    end

    callback_client.user_email
  end

  def after_logout; end
end

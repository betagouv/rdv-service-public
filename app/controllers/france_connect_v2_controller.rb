class FranceConnectV2Controller < ApplicationController
  STATE_SESSION_KEY = "france_connect_v2_state".freeze
  NONCE_SESSION_KEY = "france_connect_v2_nonce".freeze

  def auth
    auth_client = FranceConnectV2OpenIdClient::Auth.new(
      client_id: ENV["FRANCECONNECT_V2_CLIENT_ID"]
    )
    session[STATE_SESSION_KEY] = auth_client.state
    session[NONCE_SESSION_KEY] = auth_client.nonce

    redirect_to auth_client.redirect_url(omniauth_franceconnect_v2_callback_url), allow_other_host: true
  end

  def callback
    state = session[STATE_SESSION_KEY]
    nonce = session[NONCE_SESSION_KEY]
    callback_client = FranceConnectV2OpenIdClient::Callback.new(
      session_state: state,
      params_state: params[:state],
      callback_url: omniauth_franceconnect_v2_callback_url,
      nonce: nonce,
      client_id: ENV["FRANCECONNECT_V2_CLIENT_ID"],
      client_secret: ENV["FRANCECONNECT_V2_CLIENT_SECRET"]
    )

    unless callback_client.fetch_user_info_from_code!(params[:code])
      flash[:error] = generic_error_message
      redirect_to(new_user_session_path) and return
    end

    upsert_service = UpsertUserForFranceconnectService.new(OpenStruct.new(callback_client.user_info))
    upsert_service.perform
    flash[:success] = upsert_service.new_user? ? "Votre compte a été créé" : "Vous êtes connecté·e"
    bypass_sign_in upsert_service.user, scope: :user
    session[:connected_with_franceconnect] = true
    redirect_to after_sign_in_path_for(upsert_service.user)
  end

  def after_logout; end

  def sector_identifier
    urls = [
      "https://demo.rdv.numerique.gouv.fr/omniauth/franceconnect_v2/callback",
      "https://demo-rdv-solidarites-pr5352.osc-secnum-fr1.scalingo.io/omniauth/franceconnect_v2/callback",
      "http://localhost:3000/omniauth/franceconnect_v2/callback",
    ]
    render json: urls
  end

  private

  def generic_error_message
    support_email = current_domain.support_email
    %(Nous n'avons pas pu vous authentifier. Contactez le support à l'adresse <a href="mailto:#{support_email}">#{support_email}</a> si le problème persiste.)
  end
end

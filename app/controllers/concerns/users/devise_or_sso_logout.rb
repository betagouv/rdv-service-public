module Users::DeviseOrSsoLogout
  extend ActiveSupport::Concern

  # Cette méthode permet de gérer la déconnexion dans 3 cas différents :
  # - Email/Mot de passe via Devise
  # - ProConnect
  # - FranceConnect v2
  def logout_and_redirect_user(flash_message_key:)
    france_connect_v2_id_token = session.delete(:france_connect_v2_id_token)
    pro_connect_id_token = session.delete(:agent_connect_id_token)

    session.delete(:invitation) # créé par TokenInvitable
    sign_out(:user)
    set_flash_message!(:notice, flash_message_key)

    if pro_connect_id_token
      agent_connect_client = ProConnectOpenIdClient::Logout.new(pro_connect_id_token)

      redirect_to agent_connect_client.agent_connect_logout_url(root_url), allow_other_host: true

    elsif france_connect_v2_id_token
      fc_client = FranceConnectV2OpenIdClient::Logout.new(france_connect_v2_id_token)
      session[:france_connect_v2_logout_state] = fc_client.state
      redirect_to fc_client.agent_connect_logout_url(franceconnect_v2_post_logout_url), allow_other_host: true

    else
      redirect_to after_sign_out_path_for(:user)
    end
  end
end

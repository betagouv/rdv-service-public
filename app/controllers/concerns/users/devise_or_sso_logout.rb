module Users::DeviseOrSsoLogout
  extend ActiveSupport::Concern

  # Cette méthode permet de gérer la déconnexion dans 4 cas différents :
  # - Email/Mot de passe via Devise
  # - ProConnect
  # - FranceConnect v1
  # - FranceConnect v2
  def logout_and_redirect_user(flash_message_key:)
    connected_with_franceconnect_v1 = session.delete(:connected_with_franceconnect)
    france_connect_v2_id_token = session.delete(:france_connect_v2_id_token)
    pro_connect_id_token = session.delete(:agent_connect_id_token)

    sign_out(:user)
    set_flash_message!(:notice, flash_message_key)

    if pro_connect_id_token
      agent_connect_client = AgentConnectOpenIdClient::Logout.new(pro_connect_id_token)

      redirect_to agent_connect_client.agent_connect_logout_url(root_url), allow_other_host: true

    elsif france_connect_v2_id_token
      fc_client = FranceConnectV2OpenIdClient::Logout.new(france_connect_v2_id_token)
      session[:france_connect_v2_logout_state] = fc_client.state
      redirect_to fc_client.agent_connect_logout_url(franceconnect_v2_post_logout_url), allow_other_host: true

    elsif connected_with_franceconnect_v1
      redirect_to "https://#{ENV['FRANCECONNECT_HOST']}/api/v1/logout", allow_other_host: true

    else
      redirect_to after_sign_out_path_for(:user)
    end
  end
end

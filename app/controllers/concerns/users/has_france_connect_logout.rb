module Users::HasFranceConnectLogout
  extend ActiveSupport::Concern

  def handle_france_connect_logout(connected_with_franceconnect_v1: nil, france_connect_v2_id_token: nil)
    if france_connect_v2_id_token
      fc_client = FranceConnectV2OpenIdClient::Logout.new(france_connect_v2_id_token)
      session[:france_connect_v2_logout_state] = fc_client.state
      @france_connect_logout_url = fc_client.agent_connect_logout_url(omniauth_franceconnect_v2_post_logout_url)
    elsif connected_with_franceconnect_v1
      @france_connect_logout_url = "https://#{ENV['FRANCECONNECT_HOST']}/api/v1/logout"
    end
  end

  def after_sign_out_path_for(_resource_name)
    @france_connect_logout_url || super
  end
end

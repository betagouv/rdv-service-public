class Operators::SessionsController < Devise::SessionsController
  def destroy
    pro_connect_id_token = session.delete(:pro_connect_id_token)

    sign_out(:operator_manager)

    if pro_connect_id_token
      pro_connect_client = ProConnectOpenIdClient::Logout.new(pro_connect_id_token)

      redirect_to pro_connect_client.pro_connect_logout_url(root_url), allow_other_host: true
    else
      redirect_to root_path
    end
  end
end

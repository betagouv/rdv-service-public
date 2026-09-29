module SuperAdmins
  class SessionsController < ApplicationController
    def destroy
      pro_connect_id_token = session.delete(:pro_connect_id_token)
      skip_authorization
      # Effectue la déconnexion de tous les types d’utilisateurs (et supprime la session quand on fait un logout sans scope précis via Warden)
      sign_out_all_scopes

      if pro_connect_id_token.present?
        pro_connect_client = ProConnectOpenIdClient::Logout.new(pro_connect_id_token)

        redirect_to pro_connect_client.pro_connect_logout_url(root_url), allow_other_host: true
      else
        redirect_to root_path
      end
    end
  end
end

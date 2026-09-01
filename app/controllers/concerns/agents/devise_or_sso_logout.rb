module Agents::DeviseOrSsoLogout
  extend ActiveSupport::Concern

  # `sign_out` appelé avec un scope explicite (`sign_out(:agent)`, `sign_out(resource)`) ne vide pas
  # la session Rails : seules les clés Warden internes sont retirées. Sans ce nettoyage, des jetons
  # ProConnect sensibles survivraient à la déconnexion et pourraient profiter à un autre agent se
  # connectant ensuite depuis le même navigateur (poste partagé).
  def sign_out_agent!(agent_or_scope)
    session.delete(:pro_connect_access_token)
    pro_connect_id_token = session.delete(:pro_connect_id_token)
    sign_out(agent_or_scope)
    pro_connect_id_token
  end
end

module Agents::DeviseOrSsoLogout
  extend ActiveSupport::Concern
  include Agents::SessionConcern

  # `sign_out` appelé avec un scope explicite (`sign_out(:agent)`, `sign_out(resource)`) ne vide pas
  # la session Rails : seules les clés Warden internes sont retirées. Sans ce nettoyage, les données
  # stockées dans `agent_session` (jetons ProConnect, etc.) survivraient à la déconnexion et
  # pourraient profiter à un autre agent se connectant ensuite depuis le même navigateur (poste
  # partagé).
  def sign_out_agent!(agent_or_scope)
    pro_connect_id_token = agent_session[:pro_connect_id_token]
    clear_agent_session!
    sign_out(agent_or_scope)
    pro_connect_id_token
  end
end

module Agents::SessionConcern
  extend ActiveSupport::Concern

  included do
    helper_method :agent_session
  end

  # Toute donnée de session propre à un agent connecté doit passer par ce hash plutôt que par des
  # clés éparpillées à la racine de la session : ça permet de tout nettoyer d'un coup à la
  # déconnexion (`clear_agent_session!`) sans risquer d'oublier une clé au fil des évolutions, et
  # sans toucher aux autres scopes Devise potentiellement actifs dans la même session (ex : un
  # super admin connecté en tant qu'agent, cf. `session[:super_admin_signed_in_as_agent]`, qui doit
  # survivre à la déconnexion de l'agent usurpé).
  def agent_session
    session[:agent] = (session[:agent] || {}).with_indifferent_access
  end

  def clear_agent_session!
    session.delete(:agent)
  end
end

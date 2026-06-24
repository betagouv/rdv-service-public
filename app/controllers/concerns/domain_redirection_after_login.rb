module DomainRedirectionAfterLogin
  protected

  def should_redirect_to_domain_etat?(current_domain, agent)
    organisations = agent.organisations
    current_domain == Domain::RDV_SERVICE_PUBLIC &&
      agent.pro_connect_openid_sub.present? &&
      organisations.exists? &&
      organisations.all?(&:rdv_etat?)
  end

  def should_redirect_to_domain_anct?(current_domain, agent)
    organisations = agent.organisations
    current_domain == Domain::RDV_SERVICE_PUBLIC_ETAT &&
      organisations.all?(&:rdv_mairie?) &&
      agent.territories_through_organisations.all?(&:operator_id)
  end

  def redirect_target_url_in_domain(domain)
    stored_path = stored_location_for(:agent)
    if stored_path
      # on réécrit manuellement l’URL car on souhaite garder les query params du stored_path
      add_query_string_params_to_url(
        "#{request.protocol}#{domain.host_name}#{stored_path}",
        automatic_redirection_from_other_domain: "1"
      )
    else
      # On veut renvoyer vers l'URL post-connexion pour les agents par défaut (authenticated_agent_root_url)
      # Comme elle a été définie à '/' on a du en redéfinir une explicite qui ne peut pas être confondue avec
      # une route non-authentifiée
      unauthenticated_explicit_agent_root_url(
        host: domain.host_name,
        automatic_redirection_from_other_domain: "1"
      )
    end
  end
end

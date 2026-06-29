# Exemple:
# rails runner scripts/move_etat_organisations_to_new_domain.rb
#

redirection_rules = Object.new.extend(DomainRedirectionAfterLogin)

Organisation.where(verticale: :rdv_mairie).find_each do |organisation|
  admins = Agent.joins(agent_roles: :organisation).where(agent_roles: { organisation_id: organisation.id, access_level: :admin })

  all_admins_from_etat = admins.all? do |agent|
    redirection_rules.should_redirect_to_domain_etat?(Domain::RDV_SERVICE_PUBLIC, agent)
  end

  if all_admins_from_etat
    organisation.update(verticale: :rdv_etat)
  end
end

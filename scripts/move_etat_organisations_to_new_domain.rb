# Exemple:
# rails runner scripts/move_etat_organisations_to_new_domain.rb
#

Territory.find_each do |territory|
  admins = Agent.joins(territorial_roles: :territory).where(territorial_roles: { territory_id: territory.id })

  all_admins_from_etat = admins.all? do |agent|
    france_service_email = VerifiedServicePublicDomainNames.france_service?(agent.email)
    etat_email = VerifiedServicePublicDomainNames.verified?(agent.email)
    anct = agent.email&.ends_with?("anct.gouv.fr")

    agent.pro_connect_idp_id.in?(ProconnectIdentityProviders::ETAT) || (etat_email && !france_service_email && !anct)
  end

  if all_admins_from_etat
    territory.organisations.each do |organisation|
      organisation.update(verticale: :rdv_etat)
    end
  end
end

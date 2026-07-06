# Exemple:
# rails runner scripts/move_etat_organisations_to_new_domain.rb
#

# Contrairement aux noms de domaines de VerifiedServicePublicDomainNames, on ne veut pas forcément
# autoriser l'ouverture automatique de comptes pour ces noms de domaine, mais on sait qu'ils sont
# liés aux services de l'état et pas aux collectivités.
#
# Une raison de ne pas proposer l'ouverture de compte pour certains de ces noms de domaines est qu'ils
# représentent des établissements d'enseignement supérieur, et qu'il est donc possible que des étudiants
# aient des adresses email avec ces noms de domaine.
#
# Il y a aussi des centres hospitaliers dans cette liste.
ETAT_DOMAIN_NAMES = %w[
  administration.gov.pf
  aefe.fr
  agenceconsulaire.fr
  ap-hm.fr
  aphp.fr
  bio.ens.psl.eu
  bnf.fr
  cdad40.fr
  chdl-darnetal.fr
  chdl.fr
  chlaval.fr
  chru-strasbourg.fr
  cncr.fr
  cnes.fr
  conciliateurdejustice.fr
  crous-reunionmayotte.fr
  drome.cci.fr
  educagri.fr
  eesab.fr
  ehess.fr
  ens.psl.eu
  ensfea.fr
  ensiie.fr
  entpe.fr
  forets-parcnational.fr
  ftlvreunion.fr
  gh-paulguiraud.fr
  imsa.msa.fr
  imt-bs.eu
  inalco.fr
  inrae.fr
  insa-lyon.fr
  insa-rouen.fr
  insa-strasbourg.fr
  institut-agro.fr
  lecnam.net
  louvre.fr
  meteo.fr
  minesparis.psl.eu
  parcoursup.fr
  paris-belleville.archi.fr
  parisnanterre.fr
  pompiersparis.fr
  region-academique-paca.fr
  securite-ferroviaire.fr
  sorbonne-nouvelle.fr
  sorbonne-universite.fr
  telecom-paris.fr
  u-bordeaux-montaigne.fr
  u-bordeaux.fr
  u-paris.fr
  unicaen.fr
  unilim.fr
  unistra.fr
  universite-paris-saclay.fr
  utoulouse.fr
  utt.fr
  uttop.fr
].freeze

Territory.find_each do |territory|
  admins = Agent.joins(territorial_roles: :territory).where(territorial_roles: { territory_id: territory.id })

  all_admins_from_etat = admins.all? do |agent|
    france_service_email = VerifiedServicePublicDomainNames.france_service?(agent.email)
    etat_email = VerifiedServicePublicDomainNames.verified?(agent.email) || ETAT_DOMAIN_NAMES.any? do |domain_name|
      agent.email&.ends_with?(domain_name)
    end
    anct = agent.email&.ends_with?("anct.gouv.fr")

    agent.pro_connect_idp_id.in?(ProconnectIdentityProviders::ETAT) || (etat_email && !france_service_email && !anct)
  end

  # On vérifie qu'il y a au moins un admin de territoire
  if admins.present? && all_admins_from_etat
    territory.organisations.each do |organisation|
      organisation.update!(verticale: :rdv_etat)
    end
  end
end

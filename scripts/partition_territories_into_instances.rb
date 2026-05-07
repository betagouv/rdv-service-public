# Exemple:
# rails runner scripts/partition_territories_into_instances.rb

# Les noms de domaines qui confirment qu'un agent travaille pour une collectivité ou un autre partenaire de l'anct
# Vu que ça sert juste à la classification, il n'y a pas vraiment de risque de sécurité à ne pas vérifier de près ces noms
COLLECTIVITE_DOMAIN_NAMES = %w[
  7vallees.fr
  7vents.eu
  7vents.fr
  allier.fr
  alpi40.fr
  alsacedunord.fr
  amberieux-en-dombes.fr
  ambriereslesvallees.fr
  ancy-dornot.fr
  andrezieux-boutheon.com
  angersloiremetropole.fr
  annecy.fr
  annemasse-agglo.fr
  aube.fr
  aulnay-sous-bois.com
  autricourt.fr
  auvergnerhonealpes.fr
  auzeville31.fr
  avanne-aveney.com
  azeres-sur-adour.org
  bagnolsenforet.fr
  bassin-de-marennes.com
  beaulieulesloches.eu
  beauvais.fr
  belloy-en-france.fr
  berrien.fr
  beziers-mediterranee.fr
  bignan.bzh
  bois-colombes.com
  boisdennebourg.fr
  boivrelavallee.eu
  bonneuil94.fr
  bordeaux-metropole.fr
  boucbelair.fr
  bourgueil.fr
  bresnay.fr
  campbon.fr
  casson.fr
  castillonpujols.fr
  cauvaldor.fr
  cauxseine.fr
  ccasdenain.fr
  ccaslavoulte.fr
  ccasmacouria.fr
  ccasrennes.fr
  cccasavignon.org
  cdchautsperche.fr
  cdg06.fr
  cdg42.fr
  cdg46.fr
  cdg52.fr
  cdg69.fr
  cdg71.fr
  chamonix.fr
  chamonix.fr
  chasse-sur-rhone.fr
  chateauneuf-la-foret.fr
  chavignon.fr
  chemille-en-anjou.fr
  choisy.fr
  choisy.fr
  cias.paysdecraon.fr
  collectivite47.fr
  collectivitedemartinique.mq
  communaute-coutances.fr
  communaute-paysbasque.fr
  communedeanaa.pf
  communederiviere.fr
  communesalome.fr
  creuse-grand-sud.fr
  departement18.fr
  departement86.fr
  dourdan.fr
  douzy.fr
  eau-loire-bretagne.fr
  eaureunion.fr
  ecouflant.fr
  est-ensemble.fr
  etiolles.fr
  etreux.fr
  eure.fr
  fouras-les-bains.fr
  fresnes-sur-escaut.fr
  geneuille.fr
  geyssans.fr
  gieres.fr
  gourdon.fr
  grand-cognac.fr
  grand-figeac.fr
  grandbourg.fr
  grandfortphilippe.fr
  grandparissud.fr
  haute-cornouaille.bzh
  haute-cornouaille.fr
  haute-marne.fr
  hautesavoie.fr
  herault.fr
  herouvillette.fr
  holtzheim.fr
  ivry94.fr
  lacanau.fr
  lacove.fr
  ladrome.fr
  lafibre64.fr
  lagrandemotte.fr
  lamanon.fr
  lamayenne.fr
  langon33.fr
  le-gresivaudan.fr
  le-peage-de-roussillon.fr
  lebarsurloup.fr
  lehavremetro.fr
  licourt.fr
  lillemetropole.fr
  limeil.fr
  limoges.fr
  loirelayonaubance.fr
  loiret.fr
  loos-en-gohelle.fr
  loriol.com
  lormont.fr
  lyonmetropole-mmie.fr
  machilly.fr
  maconnais-sud-bourgogne.fr
  magny-vernois.fr
  mairie-pierreville.fr
  manche.fr
  marennes-oleron.com
  mareuilsurlay.fr
  maximilien.fr
  mayennecommunaute.fr
  melloisenpoitou.fr
  metropole-rouen-normandie.fr
  mommenheim.fr
  montmartin-sur-mer.fr
  montpellier.fr
  montreuil.fr
  nancy.fr
  paris.fr
  pierre-chatel.fr
  plougonvelin.fr
  pontdebuislesquimerch.fr
  portes-haut-doubs.fr
  quimperle.bzh
  rennesmetropole.fr
  salbris.fr
  sarcenas.fr
  sarzeau.fr
  saumur.fr
  sauveterre-de-guyenne.fr
  seinesaintdenis.fr
  strasbourg.eu
  terredeprovence-agglo.com
  terres-du-lauragais.fr
  terresdesconfluences.fr
  vaison-ventoux.fr
  valleedeville.fr
  vendeenumerique.fr
  vernet-les-bains.fr
  verrieres86.fr
  ville.angers.fr
  villedezuydcoote.fr
  villetassinlademilune.fr
  wahagnies.fr
  wittenheim.fr
].freeze

class Territory
  def dinum?
    admin_agents.all? { |agent| agent.email && VerifiedServicePublicDomainNames.verified?(agent.email) } ||
      admin_agents.any? { |agent| agent.pro_connect_idp_id.in?(ProconnectIdentityProviders::ETAT) } ||
      admin_agents.all? do |agent|
        domain = agent.email.split("@").last || ""
        %w[ch- chu- univ-].any? do |prefix| # Centre Hospitalier ou Centre Hospitalier Universitaire ou Université
          domain.start_with?(prefix)
        end
      end
  end

  def anct?
    operator || organisations.any?(&:ants_connectable) || admin_agents.any? do |agent|
      agent.applications.where(oauth_applications: { name: ["La Coop de la médiation numérique", "Mon Suivi Social", "RDV Aide Numérique"] }).any?
    end ||
      admin_agents.any? { |agent| agent.pro_connect_idp_id.in?(ProconnectIdentityProviders::COLLECTIVITES) } ||
      admin_agents.all? do |agent|
        domain = agent.email.split("@").last || ""
        %w[ville- agglo- cc- ccas- mairie pays saint].any? do |prefix|
          domain.start_with?(prefix)
        end
      end
  end
end

Territory.update_all(instance: nil)
Territory.where(instance: nil).find_each do |territory|
  if territory.dinum? && territory.category == "État"
    territory.update(instance: "DINUM")
  elsif territory.anct? && territory.category.in?(%w[Commune Intercommunalité Département Région])
    territory.update(instance: "ANCT")
  end
end

puts Territory.group(:instance).count

# On demandera confirmation aux agents qu'ils sont classés correctement

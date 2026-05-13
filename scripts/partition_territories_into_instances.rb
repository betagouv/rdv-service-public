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
  amilly45.fr
  ampmetropole.fr
  ancy-dornot.fr
  andrezieux-boutheon.com
  angersloiremetropole.fr
  annecy.fr
  annemasse-agglo.fr
  argonne-ardennaise.fr
  aube.fr
  aulnay-sous-bois.com
  autricourt.fr
  auvergnerhonealpes.fr
  auzeville31.fr
  avanne-aveney.com
  aves-vermandois.fr
  azeres-sur-adour.org
  bagnolsenforet.fr
  bassin-de-marennes.com
  batigere.fr
  beaulieulesloches.eu
  beauvais.fr
  belloy-en-france.fr
  berrien.fr
  beziers-mediterranee.fr
  bge-berrytouraine.com
  bignan.bzh
  bois-colombes.com
  boisdennebourg.fr
  boivrelavallee.eu
  bonneuil94.fr
  bordeaux-metropole.fr
  boucbelair.fr
  bourg-la-reine.fr
  bourgueil.fr
  bresnay.fr
  brigny.collectivite.fr
  campagnesartois.fr
  campbon.fr
  camphincarembault.fr
  casson.fr
  castillonpujols.fr
  cauvaldor.fr
  cauxseine.fr
  cazeres-sur-adour.org
  ccasavignon.org
  ccasdenain.fr
  ccaslavoulte.fr
  ccasmacouria.fr
  ccasrennes.fr
  ccbb.fr
  ccbugeysud.com
  cccasavignon.org
  ccdsv.fr
  cclouelison.fr
  ccoisans.fr
  ccplc.fr
  cdchautsperche.fr
  cdg06.fr
  cdg42.fr
  cdg46.fr
  cdg52.fr
  cdg69.fr
  cdg71.fr
  centresocial-arpajon.com
  centresocial-chemille.asso.fr
  centresocial-montbazens.fr
  centresocialdevitre.fr
  chalons-agglo.fr
  chamonix.fr
  chamonix.fr
  chasse-sur-rhone.fr
  chateauneuf-la-foret.fr
  chavignon.fr
  chemille-en-anjou.fr
  choisy.fr
  choisy.fr
  cias-hvs.fr
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
  grenoblealpesmetropole.f
  grigny91.fr
  haute-cornouaille.bzh
  haute-cornouaille.fr
  haute-marne.fr
  hautesavoie.fr
  herault.fr
  herouvillette.fr
  holtzheim.fr
  houplin-ancoisne.fr
  ivry94.fr
  lacanau.fr
  lacove.fr
  ladrome.fr
  lafibre64.fr
  lagrandemotte.fr
  lamanon.fr
  lamayenne.fr
  langon33.fr
  laverpilliere.fr
  le-drennec.fr
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
  menil53.fr
  merlimont.fr
  mesquerquimiac.fr
  metropole-rouen-normandie.fr
  mommenheim.fr
  montmartin-sur-mer.fr
  montpellier.fr
  montreuil.fr
  nancy.fr
  numeriquesudcharente.com
  paris.fr
  pierre-chatel.fr
  pithiveraisgatinais.fr
  plescop.bzh
  ploermelcommunaute.bzh
  plougonvelin.fr
  plounevez-lochrist.fr
  pontdebuislesquimerch.fr
  portes-haut-doubs.fr
  quimperle.bzh
  rennesmetropole.fr
  riomesmontagnes.fr
  salbris.fr
  sarcenas.fr
  sarzeau.fr
  saumur.fr
  sauveterre-de-guyenne.fr
  seinesaintdenis.fr
  seji.fr
  senpere64.fr
  serandon.fr
  sictomdumarsan.fr
  sidelec.re
  siea.fr
  sillery.fr
  sisteronais-buech.fr
  smica.fr
  smicval.fr
  sna27.fr
  soluris.fr
  sommenumerique.fr
  soueix-rogalle.fr
  spezet.bzh
  sqy.fr
  st-hilaire.fr
  strasbourg.eu
  sudalsace-largue.fr
  sudmessin.fr
  tencin.fr
  terredeprovence-agglo.com
  terredes2caps.com
  terres-du-lauragais.fr
  terresdesconfluences.fr
  tessybocage.fr
  thionville-fensch.fr
  thuitdeloison.fr
  ulamir-cpie.bzh
  vaison-ventoux.fr
  valaigo.fr
  valdieu-lutran.fr
  vallauris.fr
  valleedeville.fr
  var.fr
  vaugneray.com
  vaugrigneuse.fr
  vdeagglo.fr
  vendeenumerique.fr
  vernet-les-bains.fr
  verrieres86.fr
  ville.angers.fr
  villedezuydcoote.fr
  villetassinlademilune.fr
  wahagnies.fr
  wittenheim.fr
].freeze

ETAT_DOMAIN_NAMEs = %w[
  administration.gov.pf
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
]

class Territory
  def france_service?
    admin_agents.all? do |agent|
      domain = agent.email.split("@").last || ""
      domain.in?(["franceservices.gouv.fr", "france-services.gouv.fr"])
    end
  end

  def dinum?
    return false unless admin_agents.any?

    admin_agents.all? { |agent| agent.email && VerifiedServicePublicDomainNames.verified?(agent.email) } ||
      admin_agents.any? { |agent| agent.pro_connect_idp_id.in?(ProconnectIdentityProviders::ETAT) } ||
      admin_agents.all? do |agent|
        domain = agent.email.split("@").last || ""
        %w[ch- chu- univ-].any? do |prefix| # Centre Hospitalier ou Centre Hospitalier Universitaire ou Université
          domain.start_with?(prefix) || domain.in?(ETAT_DOMAIN_NAMEs)
        end
      end
  end

  def anct?
    return true if france_service?
    return false unless admin_agents.any?
    return true if mairies? # Le territorie ouvert historiquement pour les mairies

    operator || organisations.any?(&:ants_connectable) || admin_agents.any? do |agent|
      agent.applications.where(oauth_applications: { name: ["La Coop de la médiation numérique", "Mon Suivi Social", "RDV Aide Numérique"] }).any?
    end ||
      admin_agents.any? { |agent| agent.pro_connect_idp_id.in?(ProconnectIdentityProviders::COLLECTIVITES) } ||
      admin_agents.all? do |agent|
        domain = agent.email.split("@").last || ""
        %w[ville- agglo- cc- ccas- mairie pays saint udaf].any? do |prefix|
          domain.start_with?(prefix)
        end || domain.in?(COLLECTIVITE_DOMAIN_NAMES)
      end
  end
end

Territory.update_all(instance: nil)
Territory.where(instance: nil).find_each do |territory|
  if territory.dinum? && territory.anct?
    puts "Ambiguous territory: #{territory.id} #{territory.name_in_stats} (#{territory.admin_agents.count} admins)"
  elsif territory.dinum? && territory.category.in?(%w[État Opérateur Association Inconnu])
    territory.update(instance: "DINUM")
  elsif territory.anct? && territory.category.in?(%w[Commune Intercommunalité Département Région])
    territory.update(instance: "ANCT")
  end
end

puts Territory.group(:instance).count

# On demandera confirmation aux agents qu'ils sont classés correctement

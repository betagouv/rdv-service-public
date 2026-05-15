# Ce service permet de savoir si un territoire a vocation à rester sur l'instance de l'ANCT ou à être
# déplacé sur l'instance de la DINUM.
#
class FindInstanceForTerritory
  def self.find_all
    results = Hash.new(0)

    Territory.find_each do |territory|
      results[new(territory).instance] += 1
    end

    results
  end

  def initialize(territory)
    @territory = territory
  end

  # Returns :anct, :dinum, :both, or :unknown
  def instance
    anct = anct?
    dinum = dinum?

    if first_admin.nil?
      :first_admin_unkown
    elsif anct && dinum
      :both
    elsif anct
      :anct
    elsif dinum
      :dinum
    else
      :unkown
    end
  end

  def anct? # rubocop:disable Metrics/PerceivedComplexity,Metrics/CyclomaticComplexity
    return false unless first_admin&.email

    return true if @territory.mairies? # Le territorie ouvert historiquement pour les mairies

    return true if @territory.operator

    return true if france_service?

    return true if first_admin.pro_connect_idp_id.in?(ProconnectIdentityProviders::COLLECTIVITES)

    return true if first_admin_email_domain.in?(COLLECTIVITE_DOMAIN_NAMES)

    return true if @territory.organisations.any?(&:ants_connectable)

    return true if first_admin.applications.where(oauth_applications: { name: ["La Coop de la médiation numérique", "Mon Suivi Social", "RDV Aide Numérique"] }).any?

    false
  end

  def dinum?
    return false unless first_admin&.email

    return true if VerifiedServicePublicDomainNames.verified?(first_admin.email)

    return true if first_admin.pro_connect_idp_id.in?(ProconnectIdentityProviders::ETAT)

    return true if first_admin_email_domain.in?(ETAT_DOMAIN_NAMES)

    true if %w[ch- chu- univ-].any? do |prefix| # Centre Hospitalier ou Centre Hospitalier Universitaire ou Université
      first_admin_email_domain.start_with?(prefix)
    end
  end

  # Contrairement aux noms de domaines de VerifiedServicePublicDomainNames, on ne veut pas forcément
  # autoriser l'ouverture automatique de comptes pour ces noms de domaine, mais on sait qu'ils sont
  # liés aux services de l'état et pas aux collectivités.
  #
  # Une raison de ne pas proposer l'ouverture de compte pour certains de ces noms de domaines est qu'ils
  # représente des établissements d'enseignement supérieur, et qu'il est donc possible que des étudiants
  # aient des adresses email avec ces noms de domaine.
  ETAT_DOMAIN_NAMES = %w[
    administration.gov.pf
    ap-hm.fr
    aphp.fr
    bio.ens.psl.eu
    bnf.fr
    cdad40.fr
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
    insa-lyon.fr
    insa-lyon.fr
    insa-rouen.fr
    insa-strasbourg.fr
    institut-agro.fr
    meteo.fr
    minesparis.psl.eu
    parcoursup.fr
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

  COLLECTIVITE_DOMAIN_NAMES = %w[
    7vallees.fr
    7vents.eu
    7vents.fr
    adour-madiran.fr
    agglo-casa.fr
    agglopole.fr
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
    apt.fr
    argonne-ardennaise.fr
    assoflorimont.fr
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
    ccapv.fr
    ccasavignon.org
    ccasdenain.fr
    ccaslavoulte.fr
    ccasmacouria.fr
    ccasrennes.fr
    ccb3f.fr
    ccba31.fr
    ccbb.fr
    ccbugeysud.com
    cccasavignon.org
    ccdsv.fr
    cchnvy.fr
    cchpb.net
    cchvs.fr
    cciamp.com
    cclgv.fr
    cclouelison.fr
    ccmpm.fr
    ccogolin.fr
    ccoisans.fr
    ccplc.fr
    ccplm.eu
    ccplumbres.fr
    ccpm-maiche.com
    ccpom.fr
    ccqb.fr
    ccquercyblanc.fr
    cctama.fr
    ccvcommunaute.fr
    ccvp.fr
    ccvsc01.org
    ccvt.fr
    ccyn.fr
    cdcaag.fr
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
    ceze-cevennes.fr
    cg974.fr
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
    coop-numerique.anct.gouv.fr
    cornillonsurloule.fr
    cotedor.fr
    couillypontauxdames.fr
    cr-reunion.fr
    creuse-grand-sud.fr
    departement18.fr
    departement86.fr
    dourdan.fr
    douzy.fr
    dromenet.org
    eau-loire-bretagne.fr
    eaureunion.fr
    ecouflant.fr
    emmaus-connect.org
    epagebourbre.fr
    epageloirelignon.fr
    espacecentrecalais.fr
    essarts-le-roi.org
    esseylesnancy.fr
    est-ensemble.fr
    esterelcotedazur-agglo.fr
    etiolles.fr
    etreux.fr
    eure.fr
    ext.anct.gouv.fr
    eybens.fr
    flers-agglo.fr
    fougeres-agglo.bzh
    fouras-les-bains.fr
    fresnes-sur-escaut.fr
    geneuille.fr
    geyssans.fr
    gieres.fr
    gmail.com
    gourdon.fr
    grand-cognac.fr
    grand-figeac.fr
    grandbourg.fr
    grandfortphilippe.fr
    grandparissud.fr
    grenoblealpesmetropole.f
    grenoblealpesmetropole.fr
    grigny91.fr
    hautbugey-agglomeration.fr
    haute-cornouaille.bzh
    haute-cornouaille.fr
    haute-marne.fr
    hauteloire.fr
    hautesavoie.fr
    hendaye.fr
    herault.fr
    herouvillette.fr
    holtzheim.fr
    hotmail.fr
    houplin-ancoisne.fr
    iledefrance.fr
    ivry94.fr
    jauldes.fr
    lacanau.fr
    lacove.fr
    ladrome.fr
    lafibre64.fr
    lagrandemotte.fr
    lagrandemotte.fr
    lamanon.fr
    lamayenne.fr
    langon33.fr
    laposte.fr
    laposte.net
    larochesuryon.fr
    laverpilliere.fr
    le-drennec.fr
    le-gresivaudan.fr
    le-peage-de-roussillon.fr
    lebarsurloup.fr
    lehavremetro.fr
    lemesnilsaintdenis.fr
    leshautsdanjou.fr
    lesportesbriardes.fr
    licourt.fr
    lillemetropole.fr
    lillemetropole.fr
    limeil.fr
    limoges.fr
    loirelayonaubance.fr
    loiret.fr
    loos-en-gohelle.fr
    loriol.com
    lormont.fr
    lot.fr
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
    moyenmoutier.fr
    nancy.fr
    numeriquesudcharente.com
    onflentcanigo.fr
    orange.fr
    ostwald.fr
    paris.fr
    pierre-chatel.fr
    pimmsmediation.fr
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
    rivesduloirenanjou.fr
    rochechouart.com
    routenouvelle.fr
    ruralesentredeuxmers.fr
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
    suite.anct.gouv.fr
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
    wanadoo.fr
    wittenheim.fr
    yahoo.fr
  ].freeze

  private

  def france_service?
    first_admin_email_domain.in?(["france-service.gouv.fr"])
  end

  def first_admin_email_domain
    first_admin.email.split("@").last
  end

  def first_admin
    @first_admin ||= find_first_admin
  end

  # On cherche à savoir qui a ouvert l'espace
  # Parfois la création de l'espace passe par un TerritoryCreationRequest, parfois on n'a plus la
  # version PaperTrail qui correspond au creat de l'espace
  #
  # Il est possible que l'admin courant ne soit pas le même que celui qui a créé l'espace.
  #
  # La manière la plus fiable semble donc être de trouver l'admin dont le rôle a été créé en même temps
  # que l'espace (avec parfois quelques millisecondes de différence)
  def find_first_admin
    @territory.admin_agents.find do |agent|
      AgentTerritorialAccessRight.where(agent_id: agent.id, territory_id: @territory.id)
        .where("created_at > ? AND created_at < ?", @territory.created_at - 1.second, @territory.created_at + 1.second).any?
    end
  end
end

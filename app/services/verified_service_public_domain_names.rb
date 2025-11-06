# Les domaines dans ce fichier viennent principalement de ce grist fourni par l'équipe ProConnect :
# https://grist.numerique.gouv.fr/o/docs/3kQ829mp7bTy/ProConnect-Configuration-des-FI-et-FS/p/1
class VerifiedServicePublicDomainNames
  def self.verified?(email)
    DOMAINS.any? do |domain|
      email.ends_with?(domain)
    end
  end

  DOMAINS = %w[
    .gouv.fr

    @ac-amiens.fr
    @ac-besancon.fr
    @ac-bordeaux.fr
    @ac-caen.fr
    @ac-clermont.fr
    @ac-cned.fr
    @ac-corse.fr
    @ac-creteil.fr
    @ac-dijon.fr
    @ac-grenoble.fr
    @ac-guadeloupe.fr
    @ac-guyane.fr
    @ac-lille.fr
    @ac-limoges.fr
    @ac-lyon.fr
    @ac-martinique.fr
    @ac-mayotte.fr
    @ac-montpellier.fr
    @ac-nancy-metz.fr
    @ac-nantes.fr
    @ac-nice.fr
    @ac-normandie.fr
    @ac-noumea.nc
    @ac-orleans-tours.fr
    @ac-paris.fr
    @ac-poitiers.fr
    @ac-polynesie.pf
    @ac-reims.fr
    @ac-rennes.fr
    @ac-reunion.fr
    @ac-rouen.fr
    @ac-spm.fr
    @ac-strasbourg.fr
    @ac-toulouse.fr
    @ac-versailles.fr
    @ac-wf.wf
    @cned.fr
    @hceres.fr
    @region-academique-auvergne-rhone-alpes.fr
    @region-academique-bourgogne-franche-comte.fr
    @region-academique-bretagne.fr
    @region-academique-centre-val-de-loire.fr
    @region-academique-corse.fr
    @region-academique-grand-est.fr
    @region-academique-guadeloupe.fr
    @region-academique-guyane.fr
    @region-academique-hauts-de-france.fr
    @region-academique-ile-de-france.fr
    @region-academique-martinique.fr
    @region-academique-mayotte.fr
    @region-academique-normandie.fr
    @region-academique-nouvelle-aquitaine.fr
    @region-academique-occitanie.fr
    @region-academique-pays-de-la-loire.fr
    @region-academique-provence-alpes-cote-dazur.fr
    @region-academique-reunion.fr

    @pole-emploi.fr
    @france-travail.fr
    @francetravail.fr

    @ademe.fr
    @assurance-maladie.fr
    @cerema.fr

    .senat.fr

    @sante.fr
    .sante.fr

    @justice.fr
    .justice.fr
  ].freeze
end

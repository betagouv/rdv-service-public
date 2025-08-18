class Api::Justice::LieuxController < ActionController::Base # rubocop:disable Rails/ApplicationController
  # Cet endpoint renvoie des données publiques similaire à l'annuaire des services publics, donc on n'a pas besoin d'authentification
  def index
    lieux = []

    # Des données de test pour l'équipe tech de l'appli Justice.fr
    if ENV["RDV_SOLIDARITES_INSTANCE_NAME"] == "DEMO"
      lieux << {
        ee_id: "612f2ed9b473e40555def46c",
        reservation_en_ligne: false,
        url: "https://demo.rdv.anct.gouv.fr/prendre_rdv?departement=&public_link_organisation_id=877",
      }

      lieux << {
        ee_id: "612f2ed9b473e40555def46e",
        reservation_en_ligne: true,
        url: "https://demo.rdv.anct.gouv.fr/prendre_rdv?departement=&public_link_organisation_id=878",
      }
    else
      lieux = JusticeLieuxMatch.all.map do |match|
        {
          ee_id: match.ee_id,
          reservation_en_ligne: match.reservation_en_ligne,
          url: match.url,
        }
      end
    end

    render json: { lieux: }
  end
end

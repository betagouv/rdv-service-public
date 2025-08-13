class Api::Justice::LieuxController < ActionController::Base
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
    end

    render json: { lieux: }
  end
end

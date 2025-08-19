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
      lieux = matches.map do |ee_id, lieu_id|
        lieu = Lieu.find(lieu_id)
        {
          ee_id: ee_id,
          reservation_en_ligne: reservation_en_ligne(lieu),
          url: url(lieu),
        }
      end
    end

    render json: { lieux: }
  end

  private

  def reservation_en_ligne(lieu)
    lieu.plage_ouvertures.joins(:motifs).where(
      motifs: { bookable_by: :everyone },
      plage_ouvertures: { expired_cached: false }
    ).any?
  end

  def url(lieu)
    Rails.application.routes.url_helpers.public_link_to_org_url(
      organisation_id: lieu.organisation_id,
      org_slug: lieu.organisation.slug,
      host: "rdv.anct.gouv.fr"
    )
  end

  def matches
    {
      "612f2ebab473e40555dee806": 2098,
      "612f2ebfb473e40555dee9d4": 1861,
      "612f2ec1b473e40555deeb00": 1933,
      "612f2ec1b473e40555deeb08": 1932,
      "612f2ec1b473e40555deeb1a": 1926,
      "612f2ec2b473e40555deeb1c": 1927,
      "612f2ec2b473e40555deeb20": 1942,
      "612f2ec2b473e40555deeb26": 1936,
      "612f2ec1b473e40555deeb04": 1904,
      "612f2ec1b473e40555deeb06": 1906,
    }
  end
end

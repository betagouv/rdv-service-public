class Api::Justice::LieuxController < ActionController::Base # rubocop:disable Rails/ApplicationController
  # Cet endpoint renvoie des données publiques similaire à l'annuaire des services publics, donc on n'a pas besoin d'authentification
  def index
    lieux = []

    # Des données de test pour l'équipe tech de l'appli Justice.fr
    if ENV["RDV_SOLIDARITES_INSTANCE_NAME"] == "DEMO"
      lieux << {
        ee_id: "67597dc989a4c84487c231a1",
        reservation_en_ligne: false,
        url: "https://demo.rdv.anct.gouv.fr/org/939/maison-de-justice-et-du-droit-de-menton",
      }

      lieux << {
        ee_id: "67597db289a4c84487c22f1b",
        reservation_en_ligne: true,
        url: "https://demo.rdv.anct.gouv.fr/org/938/maison-de-justice-et-du-droit-de-chambery",
      }

    else
      # Il y a beaucoup de requêtes N+1 dans ce code, mais c'est acceptable tant que c'est derrière un cache
      # et qu'on a relativement peu de lieux concernées
      lieux = Rails.cache.fetch("justice/lieux_controller", expires_in: 1.hour) do
        matches.map do |ee_id, lieu_id|
          lieu = Lieu.find_by(id: lieu_id)
          next unless lieu

          {
            ee_id: ee_id,
            reservation_en_ligne: reservation_en_ligne(lieu),
            url: url(lieu),
          }
        end.compact
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

  # Cette liste est générée manuellement à partir d'un dump de données de prods en utilisant un script
  def matches
    {
      "612f2ebab473e40555dee806": 2098,
      "612f2ebfb473e40555dee9d4": 1861,
      "612f2ec1b473e40555deeb00": 1933,
      "612f2ec1b473e40555deeb04": 1904,
      "612f2ec1b473e40555deeb06": 1906,
      "612f2ec1b473e40555deeb08": 1932,
      "612f2ec1b473e40555deeb1a": 1926,
      "612f2ec2b473e40555deeb1c": 1927,
      "612f2ec2b473e40555deeb20": 1942,
      "612f2ec2b473e40555deeb26": 1936,
      "612f2ec1b473e40555deeafe": 1910,
      "612f2ec2b473e40555deeb32": 1910,
      "612f2ec2b473e40555deeb2a": 1905,
      "612f2ec1b473e40555deeb12": 1905,
      "612f2ec1b473e40555deeb18": 1935,
      "612f2ec2b473e40555deeb30": 1935,
      "612f2ed8b473e40555def3fc": 1431,
      "680126c3eb6d1e45d3eb20cb": 1621,

      # Correspondances trouvées en filtrant sur la colonne "type-organisme" avec la valeur "mjd"
      "67597dc989a4c84487c231a1" => 1163,
      "67597db289a4c84487c22f1b" => 1431,
      "67597dba89a4c84487c22ffc" => 1762,
      "67597dc289a4c84487c230c1" => 2163,
      "67597dc289a4c84487c230c3" => 1434,
      "67597df189a4c84487c23592" => 2159,
      "67597df489a4c84487c235da" => 1621,
      "67597db289a4c84487c22f19" => 1622,
      "67597dba89a4c84487c22ff4" => 1598,
      "67597dc489a4c84487c23108" => 2299,
    }
  end
end

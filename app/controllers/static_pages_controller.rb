class StaticPagesController < ApplicationController
  def mds
    redirect_to root_path unless current_domain == Domain::RDV_SOLIDARITES
    render layout: "application_base"
  end

  def accessibility; end

  def lieux_map_data
    query = <<~SQL.strip
        SELECT
        -- "source"."id" AS "id",
          "source"."latitude" AS "latitude",
          "source"."longitude" AS "longitude",
          "source"."name" AS "name",
        --   "source"."rdvs_count" AS "rdvs_count",
          "source"."organisation_name" AS "organisation_name"
        FROM (
          SELECT
            CONCAT('rdvs-', lieux.id) AS id,
            lieux.latitude,
            lieux.longitude,
            lieux.name,
            COUNT(rdvs.id) AS rdvs_count,
            organisations.name AS organisation_name
          FROM rdvs.lieux lieux
          LEFT JOIN rdvs.organisations organisations ON organisations.id = lieux.organisation_id
          LEFT JOIN rdvs.rdvs rdvs ON lieux.id = rdvs.lieu_id
          WHERE rdvs.created_at > (CURRENT_DATE - INTERVAL '2 months')
          GROUP BY lieux.id, lieux.latitude, lieux.longitude, lieux.name, organisations.name
          HAVING COUNT(rdvs.id) > 5

          UNION ALL

          SELECT
            CONCAT('rdvsp-', lieux.id) AS id,
            lieux.latitude,
            lieux.longitude,
            lieux.name,
            COUNT(rdvs.id) AS rdvs_count,
            organisations.name AS organisation_name
        FROM rdvsp.lieux lieux
        LEFT JOIN rdvsp.organisations organisations ON organisations.id = lieux.organisation_id
        LEFT JOIN rdvsp.rdvs rdvs ON lieux.id = rdvs.lieu_id
        WHERE rdvs.created_at > (CURRENT_DATE - INTERVAL '2 months')
        GROUP BY lieux.id, lieux.latitude, lieux.longitude, lieux.name, organisations.name
        HAVING COUNT(rdvs.id) > 5
      ) AS "source";
    SQL

    res = Rails.cache.fetch("lieux_map_data", expires_in: 24.hours) do
      Typhoeus.post(
        "https://rdv-service-public-metabase.osc-secnum-fr1.scalingo.io/api/dataset/json",
        params: { query: { database: 2, native: { query: }, type: "native" }.to_json },
        headers: {
          "x-api-key" => ENV["METABASE_API_KEY"],
          "Content-Type" => "application/json",
          "Accept" => "application/json",
        }
      )
    end
    if res.code != 200
      render(
        json: { error: "Erreur lors de la récupération des données, statut #{res.code}", body: res.body },
        status: :internal_server_error
      )
      return
    end

    render json: JSON.parse(res.body)
  end

  def lieux_map; end

  def contact
    territories_with_phone_number = Territory.where.not(phone_number_formatted: nil)
    territories_group_by_department = territories_with_phone_number
      .where(departement_number: Territory::DEPARTEMENTS_NAMES.keys)
      .order(:departement_number).ordered_by_name.group_by(&:departement_number)

    territories_without_department = territories_with_phone_number
      .where.not(departement_number: Territory::DEPARTEMENTS_NAMES.keys)
      .ordered_by_name

    render locals: {
      territories_group_by_department: territories_group_by_department,
      territories_without_department: territories_without_department,
    }
  end

  def domaines; end

  def presentation_for_agents
    if current_domain == Domain::RDV_MAIRIE
      redirect_to root_path # La landing page pour RDV Service Public s'adresse aux agents
    else
      render current_domain.presentation_for_agents_template_name, layout: "application_base"
    end
  end

  def microsoft_domain_verification
    # see https://learn.microsoft.com/en-us/azure/active-directory/develop/howto-configure-publisher-domain#select-a-verified-domain
    response.headers["Content-Type"] = "application/json"

    render # pour avoir un response.body sur lequel calculer Content-Length

    response.headers["Content-Length"] = response.body.length.to_s
  end
end

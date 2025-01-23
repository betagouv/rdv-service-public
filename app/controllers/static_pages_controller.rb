class StaticPagesController < ApplicationController
  def mds
    redirect_to root_path unless current_domain == Domain::RDV_SOLIDARITES
    render layout: "application_base"
  end

  def accessibility; end

  def lieux_map_data
    query = Rails.root.join("app/lib/lieux_map_query.sql").read

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

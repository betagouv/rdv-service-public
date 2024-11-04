class StaticPagesController < ApplicationController
  def mds
    redirect_to root_path unless current_domain == Domain::RDV_SOLIDARITES
    render layout: "application_base"
  end

  def accessibility; end

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
    render current_domain.presentation_for_agents_template_name, layout: "application_base"
  end

  def microsoft_domain_verification
    # see https://learn.microsoft.com/en-us/azure/active-directory/develop/howto-configure-publisher-domain#select-a-verified-domain
    response.headers["Content-Type"] = "application/json"

    render # pour avoir un response.body sur lequel calculer Content-Length

    response.headers["Content-Length"] = response.body.length.to_s
  end
end

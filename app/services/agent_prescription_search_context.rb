class AgentPrescriptionSearchContext < WebSearchContext
  STRONG_PARAMS_LIST = [
    :latitude, :longitude, :address, :city_code, :departement, :street_ban_id,
    :service_id, :lieu_id, :date, :motif_name_with_location_type, :motif_category_short_name,
    :motif_id, :user_selected_organisation_id, :prescripteur,
    { # Paramètre supplémentaire qui n'apparait pas dans le WebSearchContext
      user_ids: [],
    },
  ].freeze

  def initialize(user:, current_organisation:, agent_prescripteur:, query_params: {})
    super(user: user, query_params: query_params)
    @current_organisation = current_organisation
    @agent_prescripteur = agent_prescripteur
  end

  attr_reader :user

  def wizard_after_creneau_selection_path(creneau_params)
    url_helpers = Rails.application.routes.url_helpers
    if @user
      url_helpers.recapitulatif_admin_organisation_prescription_path(@current_organisation, creneau_params.merge(query_params))
    else
      url_helpers.user_selection_admin_organisation_prescription_path(@current_organisation, creneau_params.merge(query_params))
    end
  end

  def city_code
    geolocation_results[:city_code] if geolocation_results
  end

  def street_ban_id
    geolocation_results[:street_ban_id] if geolocation_results
  end

  def address
    @user&.address
  end

  private

  def filter_motifs(available_motifs)
    motifs = super
    restrict_agent_services? ? motifs.where(service: @agent_prescripteur.services) : motifs
  end

  def restrict_agent_services?
    # Un agent non-admin et non secrétaire ne voit que les motifs de
    # ses services, tout comme avec la prise de RDV intra-organisation.
    !@agent_prescripteur.secretaire? && !@agent_prescripteur.admin_in_organisation?(@current_organisation)
  end

  def geolocation_results
    return unless address

    @geolocation_results ||= GeoCoding.new.get_geolocation_results(address, departement)
  end
end

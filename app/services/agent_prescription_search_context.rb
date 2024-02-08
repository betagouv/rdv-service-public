class AgentPrescriptionSearchContext < WebSearchContext
  STRONG_PARAMS_LIST = [
    :latitude, :longitude, :address, :city_code, :departement, :street_ban_id,
    :service_id, :lieu_id, :date, :motif_name_with_location_type, :motif_category_short_name,
    :motif_id, :user_selected_organisation_id, :prescripteur,
    { # Paramètre supplémentaire qui n'apparait pas dans le WebSearchContext
      user_ids: [],
    },
  ].freeze

  def initialize(user:, current_organisation:, query_params: {})
    super(user: user, query_params: query_params)
    @current_organisation = current_organisation
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

  memoize def geolocation_results
    return unless address

    GeoCoding.new.get_geolocation_results(address, departement)
  end
end

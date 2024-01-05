class AgentPrescriptionSearchContext < WebSearchContext
  STRONG_PARAMS_LIST = [
    :latitude, :longitude, :address, :city_code, :departement, :street_ban_id,
    :service_id, :lieu_id, :date, :motif_name_with_location_type, :motif_category_short_name,
    :motif_id, :public_link_organisation_id, :user_selected_organisation_id, :prescripteur,
    { organisation_ids: [], referent_ids: [], external_organisation_ids: [],
      # nouveau truc
      user_ids: [], },
  ].freeze

  def filter_motifs(available_motifs)
    motifs = super
    # this in search_context.rb ?
    motifs = motifs.with_motif_category_short_name(@motif_category_short_name) if @motif_category_short_name.present?
    motifs = motifs.where(organisation_id: @organisation_ids) if @organisation_ids.present?
    motifs
  end

  def initialize(user:, query_params: {})
    super
    query_params[:user_ids] = [user.id]
  end

  def wizard_after_creneau_selection_path(creneau_params)
    url_helpers = Rails.application.routes.url_helpers
    url_helpers.recapitulatif_admin_organisation_prescription_path(Current.organisation, creneau_params.merge(query_params))
  end

  attr_reader :user
end

class WebInvitationSearchContext < InvitationSearchContext
  include Users::CreneauxWizardConcern
  attr_reader :errors, :query_params, :address, :latitude, :longitude

  def initialize(user:, query_params: {})
    super
    @user_selected_organisation_id = query_params[:user_selected_organisation_id]
    @motif_id = query_params[:motif_id]
    @motif_name_with_location_type = query_params[:motif_name_with_location_type]
    @service_id = query_params[:service_id]
    @address = query_params[:address]
    @latitude = query_params[:latitude]
    @longitude = query_params[:longitude]
  end

  # dupliqué de WebSearchContext
  def filter_motifs(available_motifs)
    motifs = super
    motifs = motifs.search_by_name_with_location_type(@motif_name_with_location_type) if @motif_name_with_location_type.present?
    motifs = motifs.where(service_id: @service_id) if @service_id.present?
    motifs = motifs.where(organisation_id: organisation_id) if organisation_id.present?
    motifs = motifs.where(id: @motif_id) if @motif_id.present?
    motifs
  end

  def invitation?
    true
  end

  def prescripteur?
    false
  end

  def organisation_id
    @user_selected_organisation_id
  end

  def public_link_organisation
    # public_link_organisation is not used in web invitation context
    nil
  end

  def motif_param_present?
    @motif_id.present? ||
      @motif_name_with_location_type.present? ||
      @motif_category_short_name.present?
  end
end

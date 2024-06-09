class WebSearchContext < SearchContext
  include Users::CreneauxWizardConcern
  attr_reader :errors, :query_params, :address, :city_code, :street_ban_id, :latitude, :longitude

  def initialize(user:, query_params: {})
    super
    @latitude = query_params[:latitude]
    @longitude = query_params[:longitude]
    @address = query_params[:address]
    @city_code = query_params[:city_code]
    @street_ban_id = query_params[:street_ban_id]
    @public_link_organisation_id = query_params[:public_link_organisation_id]
    @user_selected_organisation_id = query_params[:user_selected_organisation_id]
    @external_organisation_ids = query_params[:external_organisation_ids]
    @motif_id = query_params[:motif_id]
    @motif_category_short_name = query_params[:motif_category_short_name]
    @motif_name_with_location_type = query_params[:motif_name_with_location_type]
    @service_id = query_params[:service_id]
    @lieu_id = query_params[:lieu_id]
    @referent_ids = query_params[:referent_ids]
    @prescripteur = query_params[:prescripteur]
  end

  def invitation?
    false
  end

  def prescripteur?
    @prescripteur
  end

  def departement
    @departement ||= (@query_params[:departement] || public_link_organisation&.departement_number)
  end

  def organisation_id
    @public_link_organisation_id || @user_selected_organisation_id
  end

  def filter_motifs(available_motifs)
    motifs = super
    motifs = if prescripteur?
               motifs.where(bookable_by: %i[agents_and_prescripteurs agents_and_prescripteurs_and_invited_users everyone])
             else
               motifs.bookable_by_everyone
             end

    motifs = motifs.where(organisations: { external_id: @external_organisation_ids.compact }) if @external_organisation_ids.present?

    # dupliqué de WebInvitationSearchContext
    motifs = motifs.search_by_name_with_location_type(@motif_name_with_location_type) if @motif_name_with_location_type.present?
    motifs = motifs.where(service: service) if @service_id.present?
    motifs = motifs.where(organisation_id: organisation_id) if organisation_id.present?
    motifs = motifs.where(id: @motif_id) if @motif_id.present?
    motifs
  end

  # TODO : move this to a specific search context https://github.com/betagouv/rdv-solidarites.fr/pull/3827#discussion_r1351988739
  def public_link_organisation
    @public_link_organisation ||= \
      @public_link_organisation_id.present? ? Organisation.find(@public_link_organisation_id) : nil
  end

  def motif_param_present?
    @motif_id.present? ||
      @motif_name_with_location_type.present?
  end

  private

  attr_reader :referent_ids, :lieu_id

  def matching_motifs
    @matching_motifs ||= filter_motifs(geo_search.available_motifs)
  end
end

# frozen_string_literal: true

class InvitationSearchContext < SearchContext
  attr_reader :departement

  def initialize(user:, query_params: {})
    @user = user
    @query_params = query_params
    @departement = query_params[:departement]
    @preselected_organisation_ids = query_params[:organisation_ids]
    @motif_category_short_name = query_params[:motif_category_short_name]
    @referent_ids = query_params[:referent_ids]
    @lieu_id = query_params[:lieu_id]
    @latitude = query_params[:latitude]
    @longitude = query_params[:longitude]
    @city_code = query_params[:city_code]
    @street_ban_id = query_params[:street_ban_id]
  end

  def filter_motifs(available_motifs)
    motifs = super
    motifs = motifs.bookable_by_everyone_or_bookable_by_invited_users
    motifs = motifs.with_motif_category_short_name(@motif_category_short_name) if @motif_category_short_name.present?
    motifs = motifs.where(organisation_id: @preselected_organisation_ids) if @preselected_organisation_ids.present?
    motifs
  end

  private

  attr_reader :referent_ids, :lieu_id

  def matching_motifs
    # we retrieve the geolocalised matching motifs, if there are none we fallback
    # on the matching motifs for the organisations passed in the query_params
    @matching_motifs ||=
      filter_motifs(geo_search.available_motifs).presence || filter_motifs(
        Motif.available_for_booking.where(organisation_id: @preselected_organisation_ids).joins(:organisation)
      )
  end
end

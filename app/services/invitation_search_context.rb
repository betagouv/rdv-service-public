# frozen_string_literal: true

class InvitationSearchContext < SearchContext
  attr_reader :departement, :city_code, :street_ban_id

  INVITATION_PARAMS = %i[city_code latitude longitude departement organisation_ids street_ban_id motif_category_short_name lieu_id referent_ids].freeze

  def initialize(user:, query_params: {})
    super
    INVITATION_PARAMS.each do |param_name|
      instance_variable_set("@#{param_name}", query_params[param_name])
    end
  end

  def filter_motifs(available_motifs)
    motifs = super
    motifs = motifs.bookable_by_everyone_or_bookable_by_invited_users
    motifs = motifs.with_motif_category_short_name(@motif_category_short_name) if @motif_category_short_name.present?
    motifs = motifs.where(organisation_id: @organisation_ids) if @organisation_ids.present?
    motifs
  end

  # We use matching_motifs in API so we need to keep it public
  def matching_motifs
    # we retrieve the geolocalised matching motifs, if there are none we fallback
    # on the matching motifs for the organisations passed in the query_params
    @matching_motifs ||=
      filter_motifs(geo_search.available_motifs).presence || filter_motifs(
        Motif.available_for_booking.where(organisation_id: @organisation_ids).joins(:organisation)
      )
  end

  private

  attr_reader :referent_ids, :lieu_id
end

class InvitationSearchContext < SearchContext
  attr_reader :departement, :city_code, :street_ban_id

  INVITATION_PARAMS = %i[city_code departement street_ban_id motif_category_short_name lieu_id].freeze + [
    organisation_ids: [], referent_ids: [],
  ].freeze

  def initialize(user:, query_params: {})
    super
    INVITATION_PARAMS.each do |param_name|
      if param_name.is_a?(Hash)
        param_name.each_key do |key|
          instance_variable_set("@#{key}", query_params[key])
        end
      else
        instance_variable_set("@#{param_name}", query_params[param_name])
      end
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

    @matching_motifs = @matching_motifs.where(id: @matching_motifs.select { |motif| creneau_available?(motif) }.map(&:id))
  end

  private

  def creneau_available?(motif)
    one_month_range = Time.zone.now..(Time.zone.now + 1.month)
    if motif.phone?
      creneaux_search_for(nil, date_range, motif).creneaux.any?
    else
      motif.lieux.any? { |lieu| creneaux_search_for(lieu, one_month_range, motif).creneaux.any? }
    end
  end

  attr_reader :referent_ids, :lieu_id
end

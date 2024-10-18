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
  end

  def contactable_organisations
    @contactable_organisations ||= Organisation.where(id: @organisation_ids).contactable
  end

  def organisations_emails
    contactable_organisations.where.not(email: [nil, ""]).pluck(:email).join(",")
  end

  def motif_category_name
    @motif_category_short_name.present? ? MotifCategory.find_by(short_name: @motif_category_short_name)&.name : nil
  end

  private

  attr_reader :referent_ids, :lieu_id
end

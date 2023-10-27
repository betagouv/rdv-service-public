class Admin::SectorisationTestForm
  include ActiveModel::Model

  attr_accessor :where, :departement, :city_code, :street_ban_id, :latitude, :longitude, :current_territory

  validates :current_territory, :departement, :city_code, presence: true
  validate :correct_departement

  delegate(
    :attributions?,
    :attributions_count,
    :matching_zones,
    :available_motifs_from_attributed_organisation,
    :available_motifs_from_attributed_agent,
    :available_motifs_from_departement_organisations,
    to: :geo_search,
    allow_nil: true
  )

  def available_motifs_unique_names_and_location_types_by_service
    @available_motifs_unique_names_and_location_types_by_service = geo_search
      .available_motifs
      .to_a
      .uniq { [_1.name, _1.location_type] }
      .group_by(&:service)
  end

  private

  def correct_departement
    return true if departement == current_territory.departement_number

    errors.add(:base, "Vous ne pouvez pas tester la sectorisation du #{departement}")
  end

  def geo_search
    return nil unless valid?

    @geo_search ||= Users::GeoSearch.new(
      departement: departement,
      city_code: city_code,
      **(street_ban_id.present? ? { street_ban_id: street_ban_id } : {})
    )
  end
end

class Admin::Territories::SectorisationTestsController < Admin::Territories::BaseController
  skip_after_action :verify_policy_scoped, only: [:search]

  def search
    authorize_with_legacy_configuration_scope current_territory, :territorial_admin?

    return if params[:departement].blank? || params[:city_code].blank?

    raise Pundit::NotAuthorizedError unless current_territory.departement_number == params[:departement]

    @geo_search ||= Users::GeoSearch.new(
      departement: params[:departement],
      city_code: params[:city_code],
      street_ban_id: params[:street_ban_id]
    )
    @available_motifs_unique_names_and_location_types_by_service = @geo_search
      .available_motifs
      .to_a
      .uniq { [_1.name, _1.location_type] }
      .group_by(&:service)
  end
end

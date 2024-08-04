class Admin::Territories::SectorisationTestsController < Admin::Territories::BaseController
  # Cette action pourrait être publique car les infos qu’elle affiche sont celles présentées dans la recherche côté usagers
  # La seule information non publique est le nom des agents assignés individuellement à des secteurs
  # (la policy est appliquée dans le partial attribution)
  skip_after_action :verify_policy_scoped, only: [:search]

  def search
    return if params[:departement].blank? || params[:city_code].blank?

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

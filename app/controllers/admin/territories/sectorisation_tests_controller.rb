class Admin::Territories::SectorisationTestsController < Admin::Territories::BaseController
  # Cette action pourrait être publique car les infos qu’elle affiche sont celles présentées dans la recherche côté usagers
  # La seule information non publique est le nom des agents assignés individuellement à des secteurs
  # (la policy est appliquée dans le partial attribution)
  skip_after_action :verify_policy_scoped, only: [:search]

  def search
    @sectorisation_test_form = Admin::SectorisationTestForm.new(
      **params.permit(:where, :departement, :city_code, :street_ban_id, :latitude, :longitude)
    )
  end
end

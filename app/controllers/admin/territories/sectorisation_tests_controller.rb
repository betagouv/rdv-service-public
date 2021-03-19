class Admin::Territories::SectorisationTestsController < Admin::Territories::BaseController
  def search
    authorize_admin(
      policy_scope_admin(Organisation).where(territory: current_territory).first,
      :show?
    )
    @sectorisation_test_form = Admin::SectorisationTestForm.new(current_territory: current_territory, **sectorisation_test_params)
    @sectorisation_test_form.valid? if sectorisation_test_params.present?
  end

  private

  def sectorisation_test_params
    params.permit(:where, :departement, :city_code, :street_ban_id, :latitude, :longitude)
  end
end

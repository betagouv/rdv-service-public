class Admin::Departements::SectorisationTestsController < AgentDepartementAuthController
  def search
    authorize(policy_scope(Organisation).where(departement: current_departement.number).first, :show?)
    @sectorisation_test_form = Admin::SectorisationTestForm.new(current_departement: current_departement.to_s, **sectorisation_test_params)
    @sectorisation_test_form.valid? if sectorisation_test_params.present?
  end

  private

  def sectorisation_test_params
    params.permit(:where, :departement, :city_code, :street_ban_id, :latitude, :longitude)
  end
end

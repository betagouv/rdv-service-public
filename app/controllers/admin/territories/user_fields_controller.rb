class Admin::Territories::UserFieldsController < Admin::Territories::BaseController
  def edit
    authorize(current_territory, policy_class: Agent::TerritoryPolicy)
  end

  def update
    authorize(current_territory, policy_class: Agent::TerritoryPolicy)
    current_territory.update!(user_fields_params)

    flash[:alert] = "Configuration enregistrée"
    redirect_to action: :edit
  end

  private

  def user_fields_params
    params.require(:territory).permit(Territory::OPTIONAL_FIELD_TOGGLES.keys)
  end
end

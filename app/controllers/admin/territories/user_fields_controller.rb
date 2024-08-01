class Admin::Territories::UserFieldsController < Admin::Territories::BaseController
  def edit
    authorize_agent current_territory
  end

  def update
    authorize_agent current_territory
    current_territory.update!(user_fields_params)

    flash[:alert] = "Configuration enregistrée"
    redirect_to action: :edit
  end

  private

  def pundit_user
    current_agent
  end

  def user_fields_params
    params.require(:territory).permit(Territory::OPTIONAL_FIELD_TOGGLES.keys)
  end
end

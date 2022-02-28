# frozen_string_literal: true

class Admin::Territories::UserFieldsController < Admin::Territories::BaseController
  def edit; end

  def update
    current_territory.update!(user_fields_params)

    flash[:alert] = "Configuration enregistrée"
    redirect_to action: :edit
  end

  private

  def user_fields_params
    params.require(:territory).permit(Territory::OPTIONAL_FIELD_TOGGLES.keys)
  end
end

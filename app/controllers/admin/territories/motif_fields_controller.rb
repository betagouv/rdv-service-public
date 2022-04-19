# frozen_string_literal: true

class Admin::Territories::MotifFieldsController < Admin::Territories::BaseController
  def edit
    authorize current_territory
  end

  def update
    authorize current_territory
    current_territory.update(motif_fields_params)
    flash[:alert] = "Configuration enregistrée"
    redirect_to action: :edit
  end

  private

  def motif_fields_params
    params.require(:territory).permit(Territory::OPTIONAL_MOTIF_FIELD_TOGGLES.keys)
  end
end

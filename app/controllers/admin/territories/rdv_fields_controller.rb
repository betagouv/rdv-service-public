# frozen_string_literal: true

class Admin::Territories::RdvFieldsController < Admin::Territories::BaseController

  def edit
    authorize current_territory
  end 

  def update
    authorize current_territory
    current_territory.update(rdv_fields_params)
    redirect_to edit_admin_territory_rdv_fields_path(current_territory)
  end

  private

  def rdv_fields_params
    params.require(:territory).permit(Territory::OPTIONAL_RDV_FIELD_TOGGLES.keys)
  end
end

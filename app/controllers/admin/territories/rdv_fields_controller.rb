class Admin::Territories::RdvFieldsController < Admin::Territories::BaseController
  def edit
    authorize_with_legacy_configuration_scope current_territory
  end

  def update
    authorize_with_legacy_configuration_scope current_territory
    current_territory.update(rdv_fields_params)
    flash[:alert] = "Configuration enregistrée"
    redirect_to action: :edit
  end

  private

  def rdv_fields_params
    params.require(:territory).permit(Territory::OPTIONAL_RDV_FIELD_TOGGLES.keys + Territory::OPTIONAL_RDV_WAITING_ROOM_FIELD_TOGGLES.keys)
  end
end

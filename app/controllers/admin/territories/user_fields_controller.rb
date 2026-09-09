class Admin::Territories::UserFieldsController < Admin::Territories::BaseController
  def edit
    authorize(current_territory, policy_class: Agent::TerritoryPolicy)
  end

  def update
    authorize(current_territory, policy_class: Agent::TerritoryPolicy)
    # Les toggles de champs usager n'affectent pas `territorial_admin?` (basé sur le territoire lui-même).
    current_territory.update!(user_fields_params) # rubocop:disable RdvServicePublic/PunditAuthorizeStaleAfterMutation

    flash[:success] = "Configuration enregistrée"
    redirect_to action: :edit
  end

  private

  def user_fields_params
    params.require(:territory).permit(Territory::OPTIONAL_FIELD_TOGGLES.keys)
  end
end

class Admin::Territories::MotifCategoriesController < Admin::Territories::BaseController
  def update
    authorize(current_territory, policy_class: Agent::TerritoryPolicy)
    # `motif_category_ids` n'affecte pas `territorial_admin?` (basé sur le territoire lui-même).
    current_territory.update(motif_categories_params) # rubocop:disable RdvServicePublic/PunditAuthorizeStaleAfterMutation
    flash[:success] = "Configuration enregistrée"
    redirect_to edit_admin_territory_motif_fields_path(current_territory)
  end

  private

  def motif_categories_params
    params.fetch(:territory, { motif_category_ids: [] }).permit(motif_category_ids: [])
  end
end

class Admin::Territories::MotifCategoriesController < Admin::Territories::BaseController
  def update
    authorize_agent current_territory
    current_territory.update(motif_categories_params)
    flash[:alert] = "Configuration enregistrée"
    redirect_to edit_admin_territory_motif_fields_path(current_territory)
  end

  private

  def motif_categories_params
    params.require(:territory).permit(motif_category_ids: [])
  end
end

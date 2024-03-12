class Api::Rdvinsertion::MotifCategoryTerritoriesController < Api::Rdvinsertion::AgentAuthBaseController
  def create
    motif_category = MotifCategory.find_by(short_name: motif_category_territories_params[:motif_category_short_name])
    territory = Organisation.find(motif_category_territories_params[:organisation_id]).territory
    territory.motif_categories << motif_category unless territory.motif_categories.include?(motif_category)
    render_record territory
  end

  private

  def motif_category_territories_params
    params.permit(:motif_category_short_name, :organisation_id)
  end
end

class Api::Rdvinsertion::MotifCategoriesController < Api::Rdvinsertion::AgentAuthBaseController
  def create
    # les agents ne peuvent pas lancer cette action, seuls les superadmins rdv-insertion peuvent l'utiliser
    motif_category = MotifCategory.create!(create_motif_categories_params)
    render_record motif_category
  end

  private

  def create_motif_categories_params
    params.permit(:name, :short_name)
  end
end

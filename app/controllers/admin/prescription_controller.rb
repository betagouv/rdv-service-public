class Admin::PrescriptionController < AgentAuthController
  def search_creneau
    skip_authorization
    @context = WebSearchContext.new(user: nil, query_params: search_params)
  end

  private

  # TODO: factorize with app/controllers/search_controller.rb
  def search_params
    params.permit(
      :latitude, :longitude, :address, :city_code, :departement, :street_ban_id,
      :service_id, :lieu_id, :date, :motif_name_with_location_type, :motif_category_short_name,
      :motif_id, :public_link_organisation_id, :user_selected_organisation_id, :prescripteur,
      organisation_ids: [], referent_ids: [], external_organisation_ids: []
    )
  end
end

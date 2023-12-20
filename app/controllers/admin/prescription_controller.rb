class Admin::PrescriptionController < AgentAuthController
  def search_creneau
    skip_authorization
    # TODO: add the appropriate policy_scope
    user = User.find(params[:user_ids].first)
    @context = AgentPrescriptionSearchContext.new(user: user, query_params: search_params.merge(prescripteur: true))
  end

  def recapitulatif
    @rdv_wizard = AgentPrescriptionRdvWizard.new(search_params)
  end

  private

  # TODO: factorize with app/controllers/search_controller.rb
  def search_params
    params.permit(
      :latitude, :longitude, :address, :city_code, :departement, :street_ban_id,
      :service_id, :lieu_id, :date, :motif_name_with_location_type, :motif_category_short_name,
      :motif_id, :public_link_organisation_id, :user_selected_organisation_id, :prescripteur,
      organisation_ids: [], referent_ids: [], external_organisation_ids: [],
      # this is new :
      user_ids: []
    )
  end
end

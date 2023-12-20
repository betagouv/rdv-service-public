class Admin::PrescriptionController < AgentAuthController
  def search_creneau
    skip_authorization
    @context = context
  end

  def recapitulatif
    skip_authorization
    @rdv_wizard = AgentPrescripteurRdvWizard.new(query_params: search_params)
  end

  def create_rdv
    skip_authorization

    @rdv_wizard = AgentPrescripteurRdvWizard.new(query_params: search_params)

    rdv = @rdv_wizard.create_rdv!
    redirect_to confirmation_admin_organisation_prescription_path(rdv_id: rdv.id)
  end

  def confirmation
    skip_authorization # TODO: remove this
    @rdv = Rdv.find(params[:rdv_id])
  end

  private

  # TODO: factorize with app/controllers/search_controller.rb
  def search_params
    params.permit(
      :latitude, :longitude, :address, :city_code, :departement, :street_ban_id,
      :service_id, :lieu_id, :date, :motif_name_with_location_type, :motif_category_short_name,
      :motif_id, :public_link_organisation_id, :user_selected_organisation_id, :prescripteur, :starts_at, :rdv_collectif_id,
      organisation_ids: [], referent_ids: [], external_organisation_ids: [],
      # this is new :
      user_ids: []
    )
  end

  def user
    # TODO: add the appropriate policy_scope
    @user ||= User.find(params[:user_ids].first)
  end

  def context
    AgentPrescriptionSearchContext.new(user: user, query_params: search_params.merge(prescripteur: true))
  end
end

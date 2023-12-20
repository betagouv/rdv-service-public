class AgentPrescriptionSearchContext < WebSearchContext
  def initialize(user:, query_params: {})
    super
    query_params[:user_ids] = [user.id]
  end

  def wizard_after_creneau_selection_path(params)
    url_helpers = Rails.application.routes.url_helpers
    url_helpers.recapitulatif_admin_prescription_path(params)
  end
end

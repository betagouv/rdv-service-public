class AgentPrescriptionSearchContext < WebSearchContext
  def initialize(user:, query_params: {})
    super
    query_params[:user_ids] = [user.id]
  end

  def wizard_after_creneau_selection_path(params)
    url_helpers = Rails.application.routes.url_helpers
    url_helpers.recapitulatif_admin_prescription_path(params)
  end

  def current_step
    if !service_selected?
      :service_selection
    elsif !motif_name_and_type_selected?
      :motif_selection
    elsif requires_lieu_selection?
      :lieu_selection
    elsif requires_organisation_selection?
      :organisation_selection
    else
      :creneau_selection
    end
  end
end

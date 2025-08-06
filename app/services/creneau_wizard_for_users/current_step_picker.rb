class CreneauWizardForUsers::CurrentStepPicker
  def initialize(search_context)
    @context = search_context
  end

  def current_step
    if @context.departement.blank? && public_link_organisation_id.blank?
      :address_selection
    elsif !@context.motif_param_present?
      :motif_selection
    elsif requires_ants_pre_demandes_count_selection?
      :ants_pre_demandes_count_selection
    elsif requires_lieu_selection?
      :lieu_selection
    elsif requires_organisation_selection?
      :organisation_selection
    else
      :creneau_selection
    end
  end

  private

  def public_link_organisation_id
    @context.query_params[:public_link_organisation_id]
  end

  def requires_ants_pre_demandes_count_selection?
    @context.first_matching_motif.requires_ants_predemande_number? && (
      @context.ants_pre_demandes_count.blank? ||
      !AntsPreDemandesCountValidator.count_valid?(@context.ants_pre_demandes_count)
    )
  end

  def requires_lieu_selection?
    @context.first_matching_motif.requires_lieu? && @context.lieu.nil?
  end

  def requires_organisation_selection?
    !@context.first_matching_motif.requires_lieu? && @context.query_params[:user_selected_organisation_id].blank? && public_link_organisation_id.blank?
  end
end

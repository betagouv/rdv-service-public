module Users::CreneauxWizardConcern
  extend ActiveSupport::Concern

  # *** Method that outputs the current step for the user to complete its rdv journey ***
  def current_step
    if departement.blank? && query_params[:public_link_organisation_id].blank?
      :address_selection
    elsif !motif_param_present?
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

  def requires_organisation_selection?
    !first_matching_motif.requires_lieu? && user_selected_organisation.nil? && public_link_organisation.nil?
  end

  def user_selected_organisation
    @user_selected_organisation ||=
      @user_selected_organisation_id.present? ? Organisation.find(@user_selected_organisation_id) : nil
  end

  def requires_lieu_selection?
    first_matching_motif.requires_lieu? && lieu.nil?
  end

  def requires_ants_pre_demandes_count_selection?
    first_matching_motif.requires_ants_predemande_number? && (
      ants_pre_demandes_count.blank? ||
      !AntsPreDemandesCountValidator.count_valid?(ants_pre_demandes_count)
    )
  end
end

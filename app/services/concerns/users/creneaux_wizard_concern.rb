# frozen_string_literal: true

module Users::CreneauxWizardConcern
  extend ActiveSupport::Concern

  # *** Method that outputs the next step for the user to complete its rdv journey ***
  # *** It is used in #to_partial_path to render the matching partial view ***
  def current_step
    if departement.blank?
      :address_selection
    elsif !service_selected?
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

  def to_partial_path
    "search/#{current_step}"
  end

  def wizard_after_creneau_selection_path(params)
    url_helpers = Rails.application.routes.url_helpers
    if @prescripteur
      url_helpers.prescripteur_start_path(query_params.merge(params))
    else
      url_helpers.new_users_rdv_wizard_step_path(query_params.merge(params))
    end
  end

  def user_selected_organisation
    @user_selected_organisation ||= \
      @user_selected_organisation_id.present? ? Organisation.find(@user_selected_organisation_id) : nil
  end

  def public_link_organisation
    @public_link_organisation ||= \
      @public_link_organisation_id.present? ? Organisation.find(@public_link_organisation_id) : nil
  end

  def unique_motifs_by_name_and_location_type
    @unique_motifs_by_name_and_location_type ||= matching_motifs.uniq { [_1.name, _1.location_type] }
  end

  def first_matching_motif
    return unless motif_name_and_type_selected?

    matching_motifs.first
  end

  def lieu
    @lieu ||= @lieu_id.blank? ? nil : Lieu.find(@lieu_id)
  end

  private

  def requires_organisation_selection?
    !first_matching_motif.requires_lieu? && user_selected_organisation.nil? && public_link_organisation.nil?
  end

  def motif_name_and_type_selected?
    unique_motifs_by_name_and_location_type.length == 1
  end

  def service_selected?
    service.present?
  end

  def requires_lieu_selection?
    first_matching_motif.requires_lieu? && lieu.nil?
  end
end

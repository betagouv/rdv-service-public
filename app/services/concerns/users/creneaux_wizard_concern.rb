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

  def start_date
    query_params[:date]&.to_date || super
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

  def unique_motifs_by_name_and_location_type
    @unique_motifs_by_name_and_location_type ||= matching_motifs.uniq { [_1.name, _1.location_type] }
  end

  # next availability by organisation for motifs without lieu
  def next_availability_by_motifs_organisations
    @next_availability_by_motifs_organisations ||= matching_motifs.to_h do |motif|
      [motif.organisation, creneaux_search_for(nil, date_range, motif).next_availability]
    end.compact
  end

  def service
    @service ||= if @service_id.present?
                   Service.find(@service_id)
                 elsif services.count == 1
                   services.first
                 end
  end

  def services
    @services ||= matching_motifs.includes(:service).map(&:service).uniq.sort_by(&:name)
  end

  def lieux
    @lieux ||= \
      Lieu
        .with_open_slots_for_motifs(matching_motifs)
        .includes(:organisation)
        .sort_by { |lieu| lieu.distance(@latitude.to_f, @longitude.to_f) }
  end

  def next_availability_by_lieux
    @next_availability_by_lieux ||= lieux.index_with do |lieu|
      creneaux_search_for(
        lieu, date_range, matching_motifs.where(organisation: lieu.organisation).first
      ).next_availability
    end.compact
  end

  def shown_lieux
    next_availability_by_lieux.keys
  end

  def next_availability
    @next_availability ||= creneaux.empty? ? creneaux_search.next_availability : nil
  end

  def max_public_booking_delay
    matching_motifs.maximum("max_public_booking_delay")
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

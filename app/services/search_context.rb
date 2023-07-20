# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class SearchContext
  attr_reader :errors, :query_params, :address, :city_code, :street_ban_id, :latitude, :longitude,
              :motif_name_with_location_type, :prescripteur, :through_invitation
  alias invitation? through_invitation

  # rubocop:disable Metrics/MethodLength
  def initialize(user:, query_params: {}, through_invitation: false)
    @user = user
    @query_params = query_params
    @latitude = query_params[:latitude]
    @longitude = query_params[:longitude]
    @address = query_params[:address]
    @city_code = query_params[:city_code]
    @street_ban_id = query_params[:street_ban_id]
    @public_link_organisation_id = query_params[:public_link_organisation_id]
    @user_selected_organisation_id = query_params[:user_selected_organisation_id]
    @external_organisation_ids = query_params[:external_organisation_ids]
    @preselected_organisation_ids = query_params[:organisation_ids]
    @motif_id = query_params[:motif_id]
    @motif_search_terms = query_params[:motif_search_terms]
    @motif_category_short_name = query_params[:motif_category_short_name]
    @motif_name_with_location_type = query_params[:motif_name_with_location_type]
    @service_id = query_params[:service_id]
    @lieu_id = query_params[:lieu_id]
    @start_date = query_params[:date]
    @referent_ids = query_params[:referent_ids]
    @prescripteur = query_params[:prescripteur]
    @through_invitation = through_invitation
  end
  # rubocop:enable Metrics/MethodLength

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

  def geo_search
    Users::GeoSearch.new(departement: departement, city_code: @city_code, street_ban_id: @street_ban_id)
  end

  def departement
    @departement ||= (@query_params[:departement] || public_link_organisation&.departement_number)
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

  def requires_organisation_selection?
    !first_matching_motif.requires_lieu? && user_selected_organisation.nil? && public_link_organisation.nil?
  end

  def user_selected_organisation
    @user_selected_organisation ||= \
      @user_selected_organisation_id.present? ? Organisation.find(@user_selected_organisation_id) : nil
  end

  def public_link_organisation
    @public_link_organisation ||= \
      @public_link_organisation_id.present? ? Organisation.find(@public_link_organisation_id) : nil
  end

  def organisation_id
    @public_link_organisation_id || @user_selected_organisation_id
  end

  # next availability by organisation for motifs without lieu
  def next_availability_by_motifs_organisations
    @next_availability_by_motifs_organisations ||= matching_motifs.to_h do |motif|
      [motif.organisation, creneaux_search_for(nil, date_range, motif).next_availability]
    end.compact
  end

  def unique_motifs_by_name_and_location_type
    @unique_motifs_by_name_and_location_type ||= matching_motifs.uniq { [_1.name, _1.location_type] }
  end

  def first_matching_motif
    return unless motif_name_and_type_selected?

    matching_motifs.first
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

  def lieu
    @lieu ||= @lieu_id.blank? ? nil : Lieu.find(@lieu_id)
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

  def start_date
    @start_date&.to_date || Time.zone.today
  end

  def date_range
    start_date..(start_date + 6.days)
  end

  def max_public_booking_delay
    matching_motifs.maximum("max_public_booking_delay")
  end

  def creneaux
    @creneaux ||= creneaux_search.creneaux
      .uniq(&:starts_at) # On n'affiche qu'un créneau par horaire, même si plusieurs agents sont dispos
  end

  def available_collective_rdvs
    @available_collective_rdvs ||= creneaux_search.available_collective_rdvs
  end

  def creneaux_search
    creneaux_search_for(lieu, date_range, first_matching_motif)
  end

  def next_availability
    @next_availability ||= creneaux.empty? ? creneaux_search.next_availability : nil
  end

  def referent_agents
    @referent_agents ||= retrieve_referent_agents
  end

  def follow_up?
    @referent_ids.present?
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def filter_motifs(available_motifs)
    motifs = available_motifs
    motifs = if @prescripteur
               motifs.where(bookable_by: %i[agents_and_prescripteurs agents_and_prescripteurs_and_invited_users everyone])
             elsif invitation?
               motifs.bookable_by_everyone_or_bookable_by_invited_users
             else
               motifs.bookable_by_everyone
             end
    motifs = motifs.search_by_name_with_location_type(@motif_name_with_location_type) if @motif_name_with_location_type.present?
    motifs = motifs.where(service: service) if @service_id.present?
    motifs = motifs.search_by_text(@motif_search_terms) if @motif_search_terms.present?
    motifs = motifs.with_motif_category_short_name(@motif_category_short_name) if @motif_category_short_name.present?
    motifs = motifs.where(organisation_id: @preselected_organisation_ids) if @preselected_organisation_ids.present?
    motifs = motifs.where(organisation_id: organisation_id) if organisation_id.present?
    motifs = motifs.where(organisations: { external_id: @external_organisation_ids.compact }) if @external_organisation_ids.present?
    motifs = motifs.where(id: @motif_id) if @motif_id.present?
    motifs = motifs.with_availability_for_lieux([lieu.id]) if lieu.present?
    motifs = motifs.where(follow_up: follow_up?)
    motifs = motifs.with_availability_for_agents(referent_agents.map(&:id)) if follow_up?

    motifs
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  private

  def creneaux_search_for(lieu, date_range, motif)
    Users::CreneauxSearch.new(
      user: @user,
      motif: motif,
      lieu: lieu,
      date_range: date_range,
      geo_search: geo_search
    )
  end

  def retrieve_referent_agents
    return [] if @referent_ids.blank? || @user.nil?

    @user.referent_agents.where(id: @referent_ids)
  end

  def matching_motifs
    @matching_motifs ||= \
      if invitation?
        # we retrieve the geolocalised matching motifs, if there are none we fallback
        # on the matching motifs for the organisations passed in the query_params
        filter_motifs(geo_search.available_motifs).presence || filter_motifs(
          Motif.available_for_booking.where(organisation_id: @preselected_organisation_ids).joins(:organisation)
        )
      else
        filter_motifs(geo_search.available_motifs)
      end
  end
end
# rubocop:enable Metrics/ClassLength

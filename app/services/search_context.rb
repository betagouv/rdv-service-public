# frozen_string_literal: true

class SearchContext
  attr_reader :errors, :query, :departement, :address, :city_code, :street_ban_id, :latitude, :longitude,
              :motif_name_with_location_type

  def initialize(current_user, query = {})
    @current_user = current_user
    @query = query
    @invitation_token = query[:invitation_token]
    @latitude = query[:latitude]
    @longitude = query[:longitude]
    @address = query[:address]
    @city_code = query[:city_code]
    @departement = query[:departement]
    @street_ban_id = query[:street_ban_id]
    @organisation_ids = query[:organisation_ids]
    @motif_search_terms = query[:motif_search_terms]
    @motif_name_with_location_type = query[:motif_name_with_location_type]
    @service_id = query[:service_id]
    @lieu_id = query[:lieu_id]
    @start_date = query[:date]
    @errors = []
  end

  # *** Method that outputs the next step for the user to complete its rdv journey ***
  # *** It is used in #to_partial_parth to render the matching partial view ***
  def current_step
    # byebug
    if address.blank?
      :address_selection
    elsif !motif_selected?
      :motif_selection
    elsif lieu.nil?
      :lieu_selection
    else
      :creneau_selection
    end
  end

  def to_partial_path
    "search/#{current_step}"
  end

  def geo_search
    Users::GeoSearch.new(departement: @departement, city_code: @city_code, street_ban_id: @street_ban_id)
  end

  def valid?
    invitation? ? invitation_valid? : true
  end

  def invitation?
    @invitation_token.present?
  end

  def unique_motifs_by_name_and_location_type
    @unique_motifs_by_name_and_location_type ||= matching_motifs.uniq { [_1.name, _1.location_type] }
  end

  def selected_motif_name
    motif_selected? ? unique_motifs_by_name_and_location_type.first.name : nil
  end

  def motif_selected?
    unique_motifs_by_name_and_location_type.length == 1
  end

  def service
    @service ||= @service_id.blank? ? nil : Service.find(@service_id)
  end

  def lieu
    @lieu ||= @lieu_id.blank? ? nil : Lieu.find(@lieu_id)
  end

  def lieux
    @lieux ||= \
      Lieu
        .with_open_slots_for_motifs(@matching_motifs)
        .includes(:organisation)
        .sort_by { |lieu| lieu.distance(@latitude.to_f, @longitude.to_f) }
  end

  def next_availability_by_lieux
    @next_availability_by_lieux ||= lieux.to_h do |lieu|
      [
        lieu.id,
        creneaux_search_for(lieu, (1.week.ago.to_date..Time.zone.today)).next_availability
      ]
    end
  end

  def start_date
    @start_date&.to_date || Time.zone.today
  end

  def date_range
    start_date..(start_date + 6.days)
  end

  def max_booking_delay
    matching_motifs.maximum("max_booking_delay")
  end

  def creneaux
    @creneaux ||= creneaux_search.creneaux
  end

  def creneaux_search
    creneaux_search_for(lieu, date_range)
  end

  def next_availability
    @next_availability ||= creneaux.empty? ? creneaux_search.next_availability : nil
  end

  private

  def creneaux_search_for(lieu, date_range)
    Users::CreneauxSearch.new(
      user: @current_user || invited_user,
      motif: matching_motifs.where(organisation: lieu.organisation).first,
      lieu: lieu,
      date_range: date_range,
      geo_search: geo_search
    )
  end

  def matching_motifs
    @matching_motifs ||= begin
      motifs = if @motif_name_with_location_type.present?
                 available_motifs.search_by_name_with_location_type(@motif_name_with_location_type)
               else
                 available_motifs
               end
      motifs = motifs.where(service: service) if service.present?
      motifs = motifs.where(organisation: lieu.organisation) if lieu.present?
      motifs
    end
  end

  def available_motifs
    invitation? ? available_motifs_for_invitation : geo_search.available_motifs
  end

  def available_motifs_for_invitation
    # we retrieve the geolocalised available motifs, if there are none we fallback
    # on the availabe motifs for the organisations passed in the query
    invitation_geo_search_motifs.presence || invitation_organisations_motifs
  end

  def invitation_geo_search_motifs
    motifs = geo_search.available_motifs
    motifs = motifs.search_by_text(@motif_search_terms) if @motif_search_terms.present?
    motifs
  end

  def invitation_organisations_motifs
    motifs = Motif.available_with_plages_ouvertures.where(organisation_id: @organisation_ids)
    motifs = motifs.search_by_text(@motif_search_terms) if @motif_search_terms.present?
    motifs
  end

  def invited_user
    # rubocop:disable Rails/DynamicFindBy
    # find_by_invitation_token is a method added by the devise_invitable gem
    @invited_user ||= User.find_by_invitation_token(@invitation_token, true)
    # rubocop:enable Rails/DynamicFindBy
  end

  def invitation_valid?
    token_valid? && current_user_is_invited_user?
  end

  def token_valid?
    return true if invited_user.present?

    @errors << I18n.t("devise.invitations.invitation_token_invalid")
    false
  end

  def current_user_is_invited_user?
    return true if @current_user.blank?
    return true if @current_user == invited_user

    @errors << I18n.t("devise.invitations.current_user_mismatch")
    false
  end
end

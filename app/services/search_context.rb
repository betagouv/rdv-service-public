# frozen_string_literal: true

class SearchContext
  attr_reader :errors, :query, :departement, :address, :city_code, :street_ban_id, :latitude, :longitude

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
    @organisation_id = query[:organisation_id]
    @service_id = query[:service_id]
    @motif_id = query[:motif_id]
    @lieu_id = query[:lieu_id]
    @start_date = query[:date]
    @errors = []
  end

  # *** Method that outputs the next step for the user to complete its rdv journey ***
  # *** It is used in #to_partial_parth to render the matching partial view ***
  def current_step
    if address.blank?
      :address_selection
    elsif motif.nil?
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
    @unique_motifs_by_name_and_location_type ||= available_motifs.uniq { [_1.name, _1.location_type] }
  end

  def organisation
    @organisation ||= @organisation_id.blank? ? nil : Organisation.find(@organisation_id)
  end

  def service
    @service ||= @service_id.blank? ? nil : Service.find(@service_id)
  end

  def motif
    @motif ||= @motif_id.blank? ? nil : Motif.find(@motif_id)
  end

  def lieu
    @lieu ||= @lieu_id.blank? ? nil : Lieu.find(@lieu_id)
  end

  def lieux
    @lieux ||= \
      if motif.nil?
        Lieu.none
      else
        Lieu.for_motif(motif).includes(:organisation)
          .sort_by { |lieu| lieu.distance(@latitude.to_f, @longitude.to_f) }
      end
  end

  def next_availability_by_lieux
    @next_availability_by_lieux ||= lieux.map do |lieu|
      [
        lieu.id,
        creneaux_search_for(lieu, (1.week.ago.to_date..Time.zone.today)).next_availability
      ]
    end.to_h
  end

  def start_date
    @start_date&.to_date || Time.zone.today
  end

  def date_range
    start_date..(start_date + 6.days)
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
      user: @current_user,
      motif: motif,
      lieu: lieu,
      date_range: date_range,
      geo_search: geo_search
    )
  end

  def available_motifs
    invitation? ? available_motifs_for_invitation : geo_search.available_motifs
  end

  def available_motifs_for_invitation
    geo_search.available_motifs.where(organisation: organisation, service: service).presence ||
      Motif.available_with_plages_ouvertures.where(organisation: organisation, service: service)
  end

  def invited_user
    # rubocop:disable Rails/DynamicFindBy
    # find_by_invitation_token is a method added by the devise_invitable gem
    @invited_user ||= User.find_by_invitation_token(@invitation_token, true)
    # rubocop:enable Rails/DynamicFindBy
  end

  def invitation_valid?
    token_valid? && current_user_is_invited_user? && user_belongs_to_current_organsation?
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

  def user_belongs_to_current_organsation?
    return true if invited_user.organisation_ids.include?(organisation.id)

    @errors << I18n.t("devise.invitations.organisation_mismatch")
    false
  end
end

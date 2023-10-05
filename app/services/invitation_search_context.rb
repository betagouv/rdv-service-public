# frozen_string_literal: true

class InvitationSearchContext
  def initialize(user:, query_params: {})
    @user = user
    @query_params = query_params
    @departement = query_params[:departement]
    @preselected_organisation_ids = query_params[:organisation_ids]
    @motif_category_short_name = query_params[:motif_category_short_name]
    @referent_ids = query_params[:referent_ids]
    @lieu_id = query_params[:lieu_id]
    @latitude = query_params[:latitude]
    @longitude = query_params[:longitude]
    @city_code = query_params[:city_code]
    @street_ban_id = query_params[:street_ban_id]
  end

  def geo_search
    Users::GeoSearch.new(departement: @departement, city_code: @city_code, street_ban_id: @street_ban_id)
  end

  def lieu
    @lieu ||= @lieu_id.blank? ? nil : Lieu.find(@lieu_id)
  end

  def start_date
    @start_date&.to_date || Time.zone.today
  end

  def date_range
    start_date..(start_date + 6.days)
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

  def referent_agents
    @referent_agents ||= retrieve_referent_agents
  end

  def follow_up?
    @referent_ids.present?
  end

  def filter_motifs(available_motifs)
    motifs = available_motifs
    motifs = motifs.bookable_by_everyone_or_bookable_by_invited_users
    motifs = motifs.with_motif_category_short_name(@motif_category_short_name) if @motif_category_short_name.present?
    motifs = motifs.where(organisation_id: @preselected_organisation_ids) if @preselected_organisation_ids.present?
    motifs = motifs.with_availability_for_lieux([lieu]) if lieu.present?
    motifs = motifs.where(follow_up: follow_up?)
    motifs = motifs.with_availability_for_agents(referent_agents.map(&:id)) if follow_up?
    motifs
  end

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
    # we retrieve the geolocalised matching motifs, if there are none we fallback
    # on the matching motifs for the organisations passed in the query_params
    @matching_motifs ||=
      filter_motifs(geo_search.available_motifs).presence || filter_motifs(
        Motif.available_for_booking.where(organisation_id: @preselected_organisation_ids).joins(:organisation)
      )
  end
end

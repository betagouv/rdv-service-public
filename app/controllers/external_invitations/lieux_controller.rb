# frozen_string_literal: true

class ExternalInvitations::LieuxController < ExternalInvitations::BaseController
  before_action :retrieve_matching_motifs
  before_action :redirect_if_no_matching_motifs

  def index
    @lieux = Lieu
      .with_open_slots_for_motifs(@matching_motifs)
      .includes(:organisation)
      .sort_by { |lieu| lieu.distance(@latitude.to_f, @longitude.to_f) }
    @next_availability_by_lieux = @lieux.map do |lieu|
      [
        lieu.id,
        creneaux_search_for(lieu, (1.week.ago.to_date..Time.zone.today)).next_availability
      ]
    end.to_h
  end

  def show
    start_date = params[:date]&.to_date || Time.zone.today
    @date_range = start_date..(start_date + 6.days)
    @lieu = Lieu.find(params[:id])
    @query.merge!(lieu_id: @lieu.id)
    @next_availability = nil

    creneaux_search = creneaux_search_for(@lieu, @date_range)
    @creneaux = creneaux_search.creneaux
    @next_availability = creneaux_search.next_availability if @creneaux.empty?

    @max_booking_delay = @matching_motifs.maximum("max_booking_delay")

    respond_to do |format|
      format.html
      format.js
    end
  end

  private

  def redirect_if_no_matching_motifs
    return if @matching_motif.present?

    redirect_to external_invitations_organisation_service_motifs_path(
      organisation: @organisation, service: @service, **@query
    )
  end

  def creneaux_search_for(lieu, date_range)
    Users::CreneauxSearch.new(
      user: current_user,
      motif: @matching_motif, # there can be only one
      lieu: lieu,
      date_range: date_range,
      geo_search: @geo_search
    )
  end

  def retrieve_matching_motifs
    @matching_motifs = Motif.available_with_plages_ouvertures_for_organisation(@organisation)
      .where(id: params[:motif_id], service: @service)
    @matching_motif = @matching_motifs.first
  end
end

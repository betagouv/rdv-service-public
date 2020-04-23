class LieuxController < ApplicationController
  before_action :set_lieu_variables, only: [:index, :show]
  layout 'welcome'

  def index
    @lieux = Lieu.for_service_motif_and_departement(@service_id, @motif_name, @departement)
    return redirect_to lieu_path(@lieux.first, search: @query) if @lieux.size == 1

    @next_availability_by_lieux = {}
    unless online_bookings_suspended_because_of_corona?(@departement)
      @lieux.each do |lieu|
        @next_availability_by_lieux[lieu.id] = Creneau.next_availability_for_motif_and_lieu(@motif_name, lieu, Date.today)
      end
    end

    @lieux = @lieux.sort_by { |lieu| lieu.distance(@latitude.to_f, @longitude.to_f) }

    @organisations = Organisation.where(departement: @departement)
    return unless @organisations.empty?

    flash.now[:notice] = "La prise de RDV n’est pas encore disponible dans ce département"
    render 'welcome/index'
  end

  def show
    start_date = params[:date]&.to_date || Date.today
    @date_range = start_date..(start_date + 6.days)
    @lieu = Lieu.find(params[:id])

    if online_bookings_suspended_because_of_corona?(@departement)
      @creneaux = []
      @next_availability = nil
    else
      @creneaux = Creneau.for_motif_and_lieu_from_date_range(@motif_name, @lieu, @date_range)
      @next_availability = @creneaux.empty? ? Creneau.next_availability_for_motif_and_lieu(@motif_name, @lieu, @date_range.end) : nil
    end
    @matching_motifs = Motif.active.online.joins(:organisation).where(organisations: { departement: @departement }, name: @motif_name)
    @max_booking_delay = @matching_motifs.maximum('max_booking_delay')
    respond_to do |format|
      format.html
      format.js
    end
  end

  private

  def search_params
    params.require(:search).permit(:departement, :where, :service, :motif, :longitude, :latitude)
  end

  def set_lieu_variables
    @query = search_params.to_hash
    @departement = search_params[:departement]
    @motif_name = search_params[:motif]
    @where = search_params[:where]
    @service_id = search_params[:service]
    @service = Service.find(@service_id)
    @motif_names = Motif.names_for_service_and_departement(@service, @departement)
    @latitude = search_params[:latitude]
    @longitude = search_params[:longitude]
  end
end

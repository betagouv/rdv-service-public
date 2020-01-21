class LieuxController < ApplicationController
  layout 'welcome'

  def index
    @query = search_params.to_hash
    @departement = search_params[:departement]
    @motif = search_params[:motif]
    @where = search_params[:where]
    @service_id = search_params[:service]
    @service = Service.find(@service_id)
    @organisations = Organisation.where(departement: @departement)
    @lieux = Lieu.for_service_motif_and_departement(@service_id, @motif, @departement)
    @motifs = Motif.names_for_service_and_departement(@service, @departement)

    @next_availability_by_lieux = {}
    @lieux.each do |lieu|
      @next_availability_by_lieux[lieu.id] = Creneau.next_availability_for_motif_and_lieu(@motif, lieu, Date.today)
    end

    return redirect_to lieu_path(@lieux.first, search: @query) if @lieux.size == 1

    return unless @organisations.empty?

    flash.now[:notice] = "La prise de RDV n’est pas encore disponible dans ce département"
    render 'welcome/index'
  end

  def show
    @query = search_params.to_hash
    @departement = search_params[:departement]
    @motif = search_params[:motif]
    @where = search_params[:where]
    @service_id = search_params[:service]
    @service = Service.find(@service_id)
    @motifs = Motif.names_for_service_and_departement(@service, @departement)

    start_date = params[:date]&.to_date || Date.today
    @date_range = start_date..(start_date + 6.days)
    @lieu = Lieu.find(params[:id])
    @creneaux = Creneau.for_motif_and_lieu_from_date_range(@motif, @lieu, @date_range)
  end

  private

  def search_params
    params.require(:search).permit(:departement, :where, :service, :motif)
  end
end

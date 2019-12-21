class LieuxController < ApplicationController
  layout 'welcome'

  def index
    @query = search_params.to_hash
    @departement = search_params[:departement]
    @motif = search_params[:motif]
    @where = search_params[:where]
    @service_id = search_params[:service]
    @service = Service.find_by(id: search_params[:service])
    @organisations = Organisation.where(departement: @departement)
    @lieux = Lieu.for_motif_and_departement(@service_id, @motif, @departement)

    return redirect_to lieu_path(@lieux.first, search: @query) if @lieux.size == 1

    flash.now[:notice] = "La prise de RDV n’est pas encore disponible dans ce département" if @organisations.empty?
    return render 'welcome/index' if @organisations.empty?
  end

  def show
    @query = search_params.to_hash
    @departement = search_params[:departement]
    @motif = search_params[:motif]
    @where = search_params[:where]
    @service_id = search_params[:service]
    @date_range = Time.now.to_date..((Time.now + 6.days).to_date)
    @lieu = Lieu.find(params[:id])
    @creneaux = Creneau.for_motif_and_lieu_from_date_range(@motif, @lieu, @date_range)
  end

  private

  def search_params
    params.require(:search).permit(:departement, :where, :service, :motif)
  end
end

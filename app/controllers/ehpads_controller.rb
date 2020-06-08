class EhpadsController < ApplicationController
  before_action :set_variables, only: [:search]

  def set_variables
    search_params = params.require(:search).permit(:departement, :where, :latitude, :longitude)
    @departement = search_params[:departement]
    @latitude = search_params[:latitude]
    @longitude = search_params[:longitude]
    @where = search_params[:where]

    @service = Service.ehpad
    @motif_name = MotifLibelle::VISITE_PROCHE
  end

  def index
    @action_url = ehpads_path
    @search_label = "Adresse de l'établissement"
  end

  def search
    search = {
      departement: @departement,
      motif: @motif_name,
      where: @where,
      latitude: @latitude,
      longitude: @longitude,
      service: @service.id,
    }

    redirect_to lieux_path(search: search)
  end
end

class CreneauxController < ApplicationController
  respond_to :js

  def index
    date_from = Date.parse(creneaux_params[:from])
    @date_range = date_from..(date_from + 6.days)
    @lieu_id = creneaux_params[:lieu_id]
    @motif = creneaux_params[:motif]
    @departement = creneaux_params[:departement]
    @where = creneaux_params[:where]

    @lieu = Lieu.find(@lieu_id)

    @creneaux = Creneau.for_motif_and_lieu_from_date_range(@motif, @lieu, @date_range)

    respond_to do |format|
      format.js
    end
  end

  def creneaux_params
    params.permit(:from, :lieu_id, :motif, :where, :departement)
  end
end

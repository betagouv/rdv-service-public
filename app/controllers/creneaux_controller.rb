class CreneauxController < ApplicationController
  respond_to :js

  def index
    date_from = Date.parse(params[:from])
    @date_range = date_from..(date_from + 6.days)
    @lieu_id = params[:lieu_id]
    @motif = params[:motif]

    @lieu = Lieu.find(@lieu_id)

    @creneaux = Creneau.for_motif_and_lieu_from_date_range(@motif, @lieu, @date_range)

    respond_to do |format|
      format.js
    end
  end
end

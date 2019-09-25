class WelcomeController < ApplicationController
  layout 'welcome'

  def index; end

  def welcome_pro; end

  def search
    search_params = params.require(:search).permit(:departement, :where, :motif)

    if search_params[:motif].present?
      redirect_to welcome_motif_path(search_params[:departement], search_params[:motif], where: search_params[:where])
    else
      redirect_to welcome_departement_path(search_params[:departement], where: search_params[:where])
    end
  end

  def welcome_departement
    departement_params = params.permit(:departement, :where)
    @departement = departement_params[:departement]
    @where = departement_params[:where]

    @services = Service.with_online_motif_in_departement(@departement)
  end

  def welcome_motif
    departement_params = params.permit(:departement, :where, :motif)
    @departement = departement_params[:departement]
    @where = departement_params[:where]
    @motif = departement_params[:motif]

    @date_range = Time.now.to_date..((Time.now + 6.days).to_date)

    @lieux = Lieu.for_motif_and_departement_in_date_range(@motif, @departement, @date_range)

    @creneaux_by_lieux = {}
    @lieux.each do |lieu|
      @creneaux_by_lieux[lieu.id] = Creneau.for_motif_and_lieu_from_date_range(@motif, lieu, @date_range)
    end
  end
end

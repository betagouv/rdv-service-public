class WelcomeController < ApplicationController
  layout 'welcome'

  def index; end

  def welcome_agent
    render layout: 'welcome_agent'
  end

  def search
    search_params = params.require(:search).permit(:departement, :where, :service, :motif)

    if search_params[:service].present?
      if search_params[:motif].present?
        redirect_to welcome_motif_path(search_params[:departement], search_params[:service], search_params[:motif], where: search_params[:where])
      else
        redirect_to welcome_service_path(search_params[:departement], search_params[:service], where: search_params[:where])
      end
    else
      redirect_to welcome_departement_path(search_params[:departement], where: search_params[:where])
    end
  end

  def welcome_departement
    departement_params = params.permit(:departement, :where)
    @departement = departement_params[:departement]
    @where = departement_params[:where]
    @services = Service.with_online_and_active_motifs_for_departement(@departement)
  end

  def welcome_service
    service_params = params.permit(:departement, :where, :service)
    @departement = service_params[:departement]
    @where = service_params[:where]
    @service = Service.find(service_params[:service])

    @motifs = Motif.names_for_service_and_departement(@service, @departement)
  end

  def welcome_motif
    departement_params = params.permit(:departement, :where, :motif)
    @departement = departement_params[:departement]
    @where = departement_params[:where]
    @motif = departement_params[:motif]
    @service_id = params[:service].to_s
    @service = Service.find(@service_id)
    @motifs = Motif.names_for_service_and_departement(@service, @departement)

    @date_range = Time.now.to_date..((Time.now + 6.days).to_date)

    @lieux = Lieu.for_service_motif_and_departement(@service_id, @motif, @departement)
    @creneaux_by_lieux = {}

    @lieux.each do |lieu|
      @creneaux_by_lieux[lieu.id] = Creneau.for_motif_and_lieu_from_date_range(@motif, lieu, @date_range)
    end
  end
end

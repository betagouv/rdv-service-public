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
        redirect_to lieux_path(search: { departement: search_params[:departement], service: search_params[:service], motif: search_params[:motif], where: search_params[:where] })
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
end

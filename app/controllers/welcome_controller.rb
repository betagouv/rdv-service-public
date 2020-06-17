class WelcomeController < ApplicationController
  PERMITTED_PARAMS = [
    :departement, :where, :service, :motif_name, :latitude, :longitude
  ].freeze

  before_action :set_lieu_variables, only: [:welcome_departement, :welcome_service]

  def index; end

  def welcome_agent; end

  def search
    return redirect_to lieux_path(search: search_params) \
      if search_params[:service].present? && search_params[:motif_name].present?

    if search_params[:service].present?
      return redirect_to welcome_service_path(
        search_params[:departement],
        search_params[:service],
        **search_params.except(:departement, :service)
      )
    end

    if search_params[:departement].present?
      return redirect_to welcome_departement_path(
        search_params[:departement],
        **search_params.except(:departement)
      )
    end

    flash[:error] = "L'adresse entrée n'est pas valide. Vous devez choisir une des valeurs proposées sur le champ adresse."
    redirect_to root_path
  end

  def welcome_departement
    @services = Service.with_online_and_active_motifs_for_departement(@departement)
  end

  def welcome_service
    @motif_names = Motif.names_for_service_and_departement(@service, @departement)
  end

  def set_lieu_variables
    @departement = lieu_params[:departement]
    @latitude = lieu_params[:latitude]
    @longitude = lieu_params[:longitude]
    @where = lieu_params[:where]
    @service = Service.find(lieu_params[:service]) if lieu_params[:service]
  end

  private

  def search_params
    params.require(:search).permit(*PERMITTED_PARAMS)
  end

  def lieu_params
    params.permit(*PERMITTED_PARAMS)
  end
end

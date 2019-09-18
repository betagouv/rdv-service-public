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

    organisations_ids_from_departement = Organisation.where(departement: @departement).pluck(:id)
    services_ids_with_at_least_one_motif = Motif.where(organisation_id: organisations_ids_from_departement).pluck(:service_id).uniq
    @services = Service.where(id: services_ids_with_at_least_one_motif).includes(:motifs)
  end

  def welcome_motif
    departement_params = params.permit(:departement, :where, :motif)
    @departement = departement_params[:departement]
    @where = departement_params[:where]
    @motif = departement_params[:motif]

    organisations_ids_from_departement = Organisation.where(departement: @departement).pluck(:id)
    services_ids_with_at_least_one_motif = Motif.where(organisation_id: organisations_ids_from_departement).pluck(:service_id).uniq
    @services = Service.where(id: services_ids_with_at_least_one_motif).includes(:motifs)
  end
end

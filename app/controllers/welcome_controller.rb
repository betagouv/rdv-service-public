class WelcomeController < ApplicationController
  layout 'welcome'

  def index; end

  def welcome_pro; end

  def search
    where_params = params.require(:search).permit(:where_zip, :where)
    zip = where_params[:where_zip]
    departement = zip[0..1]

    redirect_to welcome_departement_path(departement, where: where_params[:where])
  end

  def welcome_departement
    departement_params = params.permit(:departement, :where)
    @departement = departement_params[:departement]
    @where = departement_params[:where]

    organisations_ids_from_departement = Organisation.where(departement: @departement).pluck(:id)
    services_ids_with_at_least_one_motif = Motif.where(organisation_id: organisations_ids_from_departement).pluck(:service_id).uniq
    @services = Service.where(id: services_ids_with_at_least_one_motif).includes(:motifs)
  end
end

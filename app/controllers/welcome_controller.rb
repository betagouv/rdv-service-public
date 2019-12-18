class WelcomeController < ApplicationController
  layout 'welcome'

  def index; end

  def welcome_agent
    render layout: 'welcome_agent'
  end

  def search
    departement = search_params[:departement]
    @motif = search_params[:motif]
    @where = search_params[:where]
    @service_id = search_params[:service]
    organisations = Organisation.where(departement: departement)

    if @motif.present? && departement.present? && !organisations.empty?
      return redirect_to welcome_motif_path(departement, @motif, where: @where, service_id: @service_id)
    end

    flash.now[:notice] = "La prise de RDV n’est pas encore disponible dans ce département" if organisations.empty?
    render :index
  end

  def welcome_motif
    @departement = params[:departement]
    @where = params[:where]
    @motif = params[:motif]
    @service_id = params[:service_id].to_s

    @date_range = Time.now.to_date..((Time.now + 6.days).to_date)

    @lieux = Lieu.for_motif_and_departement(@service_id, @motif, @departement)

    @creneaux_by_lieux = {}
    @lieux.each do |lieu|
      @creneaux_by_lieux[lieu.id] = Creneau.for_motif_and_lieu_from_date_range(@motif, lieu, @date_range)
    end
  end

  private

  def search_params
    params.require(:search).permit(:departement, :where, :service, :motif)
  end
end

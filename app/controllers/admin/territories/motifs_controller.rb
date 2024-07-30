class Admin::Territories::MotifsController < Admin::Territories::BaseController
  def index
    @organisations = current_territory.organisations
    @services = current_territory.services.reject(&:secretariat?)

    @motifs = policy_scope(Motif, policy_scope_class: Agent::MotifPolicy::Scope)
      .active
      .order({ name: :asc, service_id: :asc, location_type: :asc, organisation_id: :asc })
      .page(page_number)
      .per(100)
      .includes(:organisation)

    if params[:search].present?
      @motifs = @motifs.per(500)
    end

    @motifs = filter_motifs(@motifs)
    @motifs_count = @motifs.total_count
  end

  def new
    skip_authorization
    @motif = Motif.new
  end

  def create
    if params[:organisation_ids]&.compact_blank.blank?
      skip_authorization
      flash.now[:error] = "Sélectionner au moins une organisation"
      @motif = Motif.new(motif_params)
      render :new and return
    end

    organisations = Organisation.where(id: params[:organisation_ids])
    service = Admin::CreateMotifs.new(motif_params: motif_params, organisations: organisations)
    service.motifs.each do |motif|
      authorize(motif, :create?, policy_class: Agent::MotifPolicy)
    end

    if service.save
      flash[:notice] = "Le motif a été créé dans les organisations sélectionnées"
      filters = { search: motif_params[:name], service_ids: [motif_params[:service_id]], location_type: motif_params[:location_type] }
      redirect_to admin_territory_motifs_path(current_territory, filters)
    else
      flash.now[:error] = service.errors.to_a.join("<br>")
      @motif = service.motifs.first
      @motif.organisation = nil
      @motif.errors.clear
      render :new
    end
  end

  def destroy
    motif = Motif.active.find(params[:id])
    authorize(motif, policy_class: Agent::MotifPolicy)
    if motif.soft_delete
      flash[:notice] = "Le motif a été supprimé."
    else
      flash[:error] = "Impossible de supprimer le motif : #{motif.errors.full_messages.join(', ')}"
    end
    redirect_back fallback_location: admin_territory_motifs_path(current_territory)
  end

  private

  def filter_motifs(motifs)
    motifs = motifs.search_by_text(params[:search]) if params[:search].present?
    motifs = motifs.where(organisation_id: params[:organisation_ids]) if params[:organisation_ids].present?
    motifs = motifs.where(service_id: params[:service_ids]) if params[:service_ids].present?
    motifs = motifs.where(location_type: params[:location_type]) if params[:location_type].present?
    motifs = motifs.where(collectif: params[:collectif].to_b) if params[:collectif].present?
    motifs = motifs.where(bookable_by: params[:bookable_by]) if params[:bookable_by].present?
    motifs
  end

  def motif_params
    params.require(:motif).permit(*Admin::MotifsController::FORM_ATTRIBUTES)
  end

  def pundit_user
    current_agent
  end
end

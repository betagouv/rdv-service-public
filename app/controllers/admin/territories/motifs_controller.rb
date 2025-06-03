class Admin::Territories::MotifsController < Admin::Territories::BaseController
  before_action :set_organisations

  def index
    @current_tab = params[:current_tab] == "archived" ? :archived : :active
    @services = current_territory.services.reject(&:secretariat?)

    unfiltered_motifs = policy_scope(Motif, policy_scope_class: Agent::MotifPolicy::Scope)
    @filtered_motifs = filter_motifs(unfiltered_motifs)
      .where(organisation: @organisations)

    @motifs_page = @filtered_motifs.page(page_number)
      .active(@current_tab == :active)
      .per(100)
      .order({ name: :asc, service_id: :asc, location_type: :asc, organisation_id: :asc })
      .includes(:organisation)

    if params[:search].present?
      @motifs_page = @motifs_page.per(500)
    end
  end

  def batch_edit
    @motifs = Motif.where(id: params[:motif_ids])
    @motifs.each do |motif|
      authorize(motif, :edit?, policy_class: Agent::MotifPolicy)
    end
  end

  UPDATABLE_ATTRS = %i[
    name
    service_id
    default_duration_in_min
    color
    restriction_for_rdv
    instruction_for_rdv
    custom_cancel_warning_message
  ].freeze

  def batch_update # rubocop:disable Metrics/PerceivedComplexity
    @motifs = Motif.where(id: params[:motif_ids])
    @motifs.each do |motif|
      authorize(motif, :update?, policy_class: Agent::MotifPolicy)
    end

    permitted_params = params.permit(*UPDATABLE_ATTRS).compact_blank
    Motif.transaction do
      @motifs.each do |motif|
        motif.update(permitted_params)
      end

      raise ActiveRecord::Rollback unless @motifs.all?(&:valid?)
    end

    invalid_motifs = @motifs.select(&:invalid?)

    if invalid_motifs.none?
      flash[:success] = "Motifs modifiés"
    else
      flash[:error] = invalid_motifs.map do |invalid_motif|
        "Motif #{invalid_motif.id} : #{invalid_motif.errors.full_messages.join(', ')}"
      end.join("<br>")
    end

    redirect_to batch_edit_admin_territory_motifs_path(motif_ids: params[:motif_ids])
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
      @motif = service.motif_for_form
      render :new
    end
  end

  def archive
    motif = Motif.active.find(params[:id])
    authorize(motif, policy_class: Agent::MotifPolicy)
    motif.archive
    flash[:notice] = "Le motif #{link_to_motif(motif)} a été archivé."
    redirect_back fallback_location: admin_territory_motifs_path(current_territory)
  end

  def unarchive
    motif = Motif.find(params[:id])
    authorize(motif, policy_class: Agent::MotifPolicy)
    if motif.unarchive
      flash[:notice] = "Le motif #{link_to_motif(motif)} a été réactivé."
    else
      flash[:error] = motif.errors.full_messages.join(", ")
    end
    redirect_back fallback_location: admin_territory_motifs_path(current_territory)
  end

  def destroy
    motif = Motif.find(params[:id])
    authorize(motif, policy_class: Agent::MotifPolicy)
    if motif.destroyable?
      motif.destroy!
      flash[:notice] = "Le motif #{motif.name} a été supprimé."
      redirect_to admin_organisation_motifs_path(motif.organisation)
    else
      flash[:error] = "Impossible de supprimer le motif : il est lié à #{motif.rdvs.count} rendez-vous."
      redirect_back fallback_location: admin_organisation_motifs_path(motif.organisation)
    end
  end

  private

  def link_to_motif(motif)
    helpers.link_to(motif.name, admin_organisation_motif_path(motif.organisation, motif))
  end

  def set_organisations
    @organisations = Agent::MotifPolicy.organisations_i_can_manage(current_agent).where(territory: current_territory).ordered_by_name
  end

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
end

class Admin::MotifsController < AgentAuthController
  respond_to :html, :json

  CONSIGNE_FORM_ATTRIBUTES = %i[
    restriction_for_rdv
    instruction_for_rdv
    custom_cancel_warning_message
  ].freeze

  ADVANCED_OPTIONS_FORM_ATTRIBUTES = %i[
    follow_up
    prescription
    visibility_type
    for_secretariat
  ].freeze

  FORM_ATTRIBUTES = (%i[
    name
    service_id
    organisation_id
    color
    motif_category_id
    default_duration_in_min
    location_type
    collectif
    duplicated_from_motif_id
  ] + CONSIGNE_FORM_ATTRIBUTES + ADVANCED_OPTIONS_FORM_ATTRIBUTES).freeze

  before_action :set_organisation, only: %i[new create]
  before_action :set_motif, only: %i[show edit update archive unarchive destroy edit_consignes update_consignes edit_advanced_options update_advanced_options]

  def index
    @current_tab = params[:current_tab] == "archived" ? :archived : :active

    unfiltered_motifs = policy_scope(current_organisation.motifs, policy_scope_class: Agent::MotifPolicy::Scope)
    @filtered_motifs = filtered(unfiltered_motifs, params)
    @need_search = enough_motifs_to_need_search?(unfiltered_motifs)
    @display_services = current_territory.services.any? || current_organisation.motifs.where.not(service_id: nil).any?

    @motifs_page = @filtered_motifs
      .active(@current_tab == :active)
      .includes(:organisation, :service).page(page_number)
  end

  def new
    @motif = Motif.new(organisation: current_organisation)

    source_motif = Agent::MotifPolicy::Scope.new(current_agent, Motif).resolve.find_by(id: params[:duplicated_from_motif_id] || params.dig(:motif, :duplicated_from_motif_id))
    if source_motif
      @motif.assign_attributes(source_motif.attributes.symbolize_keys.slice(*(FORM_ATTRIBUTES + params_copied_during_duplication)))
      @motif.duplicated_from_motif_id = source_motif.id
    end

    authorize(@motif, policy_class: Agent::MotifPolicy)
  end

  def edit
    authorize(@motif, policy_class: Agent::MotifPolicy)
  end

  def show
    authorize(@motif, policy_class: Agent::MotifPolicy)
    @motif_policy = Agent::MotifPolicy.new(current_agent, @motif)
  end

  def create
    @motif = Motif.new

    source_motif = Agent::MotifPolicy::Scope.new(current_agent, Motif).resolve.find_by(id: params[:duplicated_from_motif_id] || params.dig(:motif, :duplicated_from_motif_id))

    if source_motif
      @motif.assign_attributes(source_motif.attributes.symbolize_keys.slice(*params_copied_during_duplication))
    end

    @motif.assign_attributes(motif_params)
    @motif.organisation ||= current_organisation
    authorize(@motif, policy_class: Agent::MotifPolicy)
    if @motif.save
      flash[:success] = "Motif créé."
      if current_organisation.motifs.active.count == 1
        flash[:onboarding] = "first_motif_created"
      end
      redirect_to admin_organisation_motifs_path(@motif.organisation)
    else
      render :new
    end
  end

  def update
    authorize(@motif, policy_class: Agent::MotifPolicy)

    @motif.assign_attributes(motif_params)
    authorize(@motif, policy_class: Agent::MotifPolicy)

    if @motif.save
      flash[:success] = "Le motif #{link_to_motif(@motif)} a été modifié."
      redirect_to admin_organisation_motif_path(@motif.organisation, @motif)
    else
      render :edit
    end
  end

  def edit_consignes
    authorize(@motif, :edit?, policy_class: Agent::MotifPolicy)
  end

  def update_consignes
    authorize(@motif, :update?, policy_class: Agent::MotifPolicy)

    @motif.assign_attributes(params.require(:motif).permit(CONSIGNE_FORM_ATTRIBUTES))

    authorize(@motif, :update?, policy_class: Agent::MotifPolicy)

    if @motif.save
      flash[:success] = "Les consignes du motif #{@motif.name} ont été modifiées."
      redirect_to admin_organisation_motif_path(@motif.organisation, @motif)
    else
      render :edit_consignes
    end
  end

  def edit_advanced_options
    authorize(@motif, :edit?, policy_class: Agent::MotifPolicy)
  end

  def update_advanced_options
    authorize(@motif, :update?, policy_class: Agent::MotifPolicy)

    update_advanced_options_params = params.require(:motif).permit(ADVANCED_OPTIONS_FORM_ATTRIBUTES).tap do |form_params|
      self.class.normalize_prescription_form_param(form_params)
    end
    @motif.assign_attributes(update_advanced_options_params)

    authorize(@motif, :update?, policy_class: Agent::MotifPolicy)

    if @motif.save
      flash[:success] = "Les options avancées du motif #{@motif.name} ont été modifiées."
      redirect_to admin_organisation_motif_path(@motif.organisation, @motif)
    else
      render :edit_consignes
    end
  end

  def archive
    authorize(@motif, policy_class: Agent::MotifPolicy)
    @motif.archive
    flash[:success] = "Le motif #{link_to_motif(@motif)} a été archivé."
    redirect_back fallback_location: admin_organisation_motif_path(@motif.organisation, @motif)
  end

  def unarchive
    authorize(@motif, policy_class: Agent::MotifPolicy)
    if @motif.unarchive
      flash[:success] = "Le motif #{link_to_motif(@motif)} a été réactivé."
    else
      flash[:error] = @motif.errors.full_messages.join(", ")
    end
    redirect_back fallback_location: admin_organisation_motif_path(@motif.organisation, @motif)
  end

  def destroy
    authorize(@motif, policy_class: Agent::MotifPolicy)
    if @motif.destroyable?
      @motif.destroy!
      flash[:notice] = "Le motif #{@motif.name} a été supprimé."
      redirect_to admin_organisation_motifs_path(@motif.organisation)
    else
      flash[:error] = "Impossible de supprimer le motif : il est lié à #{@motif.rdvs.count} rendez-vous."
      redirect_back fallback_location: admin_organisation_motifs_path(@motif.organisation)
    end
  end

  def self.normalize_prescription_form_param(form_params)
    if form_params.key?("prescription")
      prescription = form_params.delete("prescription").to_boolean
      form_params[:bookable_by] = prescription ? :agents_and_prescripteurs : :agents
    end
  end

  private

  def motif_params
    params.require(:motif).permit(*FORM_ATTRIBUTES).tap do |form_params|
      self.class.normalize_prescription_form_param(form_params)
    end
  end

  def params_copied_during_duplication
    %i[sectorisation_level min_public_booking_delay max_public_booking_delay bookable_by
       rdvs_editable_by_user restriction_for_rdv]
  end

  def display_sectorisation_level?
    @display_sectorisation_level ||= current_organisation.motifs.active.where.not(sectorisation_level: Motif::SECTORISATION_LEVEL_DEPARTEMENT).any?
  end
  helper_method :display_sectorisation_level?

  def pundit_user
    current_agent
  end

  def filtered(motifs, params)
    motifs = params[:search].present? ? motifs.search_by_text(params[:search]) : motifs.ordered_by_name
    motifs = online_filtered(motifs, params[:online_filter]) if params[:online_filter].present?
    motifs = motifs.where(service_id: params[:service_filter]) if params[:service_filter].present?
    motifs = motifs.where(location_type: params[:location_type_filter]) if params[:location_type_filter].present?
    motifs
  end

  def online_filtered(motifs, online_filter)
    if online_filter == "En ligne"
      motifs.bookable_by_everyone_or_bookable_by_invited_users
    else
      motifs.not_bookable_by_everyone_or_not_bookable_by_invited_users
    end
  end

  def set_motif
    @motif = policy_scope(current_organisation.motifs, policy_scope_class: Agent::MotifPolicy::Scope)
      .find(params[:id])
  end

  def link_to_motif(motif)
    helpers.link_to(motif.name, admin_organisation_motif_path(motif.organisation, motif))
  end

  def agent_can_create_motif?
    @agent_can_create_motif ||= Agent::MotifPolicy.new(current_agent, Motif.new(organisation: current_organisation)).create?
  end
  helper_method :agent_can_create_motif?

  def enough_motifs_to_need_search?(motif_scope)
    motif_scope.limit(10).count == 10
  end
end

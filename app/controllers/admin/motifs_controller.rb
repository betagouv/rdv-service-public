# frozen_string_literal: true

class Admin::MotifsController < AgentAuthController
  respond_to :html, :json

  before_action :set_organisation, only: %i[new create]
  before_action :set_motif, only: %i[show edit update destroy]

  def index
    @unfiltered_motifs = policy_scope(Motif).active
    @motifs = params[:search].present? ? @unfiltered_motifs.search_by_text(params[:search]) : @unfiltered_motifs
    @motifs = filtered(@motifs, params)
    @motifs = @motifs.includes(:organisation).includes(:service).ordered_by_name.page(params[:page])

    @sectors_attributed_to_organisation_count = Sector.attributed_to_organisation(current_organisation).count
    @sectorisation_level_agent_counts_by_service = SectorAttribution.level_agent_grouped_by_service(current_organisation)
    @display_sectorisation_level = current_organisation.motifs.where.not(sectorisation_level: Motif::SECTORISATION_LEVEL_DEPARTEMENT).any?
  end

  def new
    @motif = Motif.new(organisation_id: current_organisation.id)
    authorize(@motif)
  end

  def edit
    authorize(@motif)
  end

  def show
    authorize(@motif)
  end

  def create
    @motif = Motif.new(motif_params)
    @motif.organisation = @organisation
    authorize(@motif)
    if @motif.save
      flash[:notice] = "Motif créé."
      redirect_to admin_organisation_motifs_path(@motif.organisation)
    else
      render :new
    end
  end

  def update
    authorize(@motif)
    if @motif.update(motif_params)
      flash[:notice] = "Le motif a été modifié."
      redirect_to admin_organisation_motif_path(@motif.organisation, @motif)
    else
      render :edit
    end
  end

  def destroy
    authorize(@motif)
    if @motif.soft_delete
      flash[:notice] = "Le motif a été supprimé."
      redirect_to admin_organisation_motifs_path(@motif.organisation)
    else
      render :show
    end
  end

  private

  def filtered(motifs, params)
    motifs = online_filtered(motifs, params[:online_filter]) if params[:online_filter].present?
    motifs = motifs.where(service_id: params[:service_filter]) if params[:service_filter].present?
    motifs = motifs.where(location_type: params[:location_type_filter]) if params[:location_type_filter].present?
    motifs
  end

  def online_filtered(motifs, online_filter)
    if online_filter == "En ligne"
      motifs.reservable_online
    else
      motifs.not_reservable_online
    end
  end

  def set_motif
    @motif = policy_scope(Motif).find(params[:id])
  end

  def motif_params
    params.require(:motif)
      .permit(:name, :service_id,
              :color,
              :default_duration_in_min,
              :reservable_online,
              :location_type,
              :max_booking_delay,
              :min_booking_delay,
              :visibility_type,
              :restriction_for_rdv,
              :instruction_for_rdv,
              :cancel_warning_message,
              :for_secretariat,
              :follow_up,
              :sectorisation_level)
  end
end

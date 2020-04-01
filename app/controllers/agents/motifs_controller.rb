class Agents::MotifsController < AgentAuthController
  respond_to :html, :json

  before_action :set_organisation, only: [:new, :create]
  before_action :set_motif, only: [:show, :edit, :update, :destroy]

  def index
    @motifs = policy_scope(Motif).includes(:organisation).active.includes(:service).order(Arel.sql('LOWER(name)')).page(params[:page])
  end

  def new
    @motif = Motif.new(organisation_id: current_organisation.id)
    authorize(@motif)
    respond_right_bar_with @motif
  end

  def show
    authorize(@motif)
    respond_right_bar_with @motif
  end

  def edit
    authorize(@motif)
    respond_right_bar_with @motif
  end

  def create
    @motif = Motif.where(name: motif_params[:name], organisation_id: @organisation.id).first_or_initialize(motif_params)
    authorize(@motif)
    if @motif.id
      @motif.update(motif_params.merge(deleted_at: nil))
    else
      @motif.organisation = @organisation
      flash[:notice] = "Motif créé." if @motif.save
    end
    respond_right_bar_with @motif, location: organisation_motifs_path(@motif.organisation)
  end

  def update
    authorize(@motif)
    flash[:notice] = "Le motif a été modifié." if @motif.update(motif_params)
    respond_right_bar_with @motif, location: organisation_motifs_path(@motif.organisation)
  end

  def destroy
    authorize(@motif)
    flash[:notice] = "Le motif a été supprimé." if @motif.soft_delete
    respond_right_bar_with @motif, location: organisation_motifs_path(@motif.organisation)
  end

  private

  def set_motif
    @motif = policy_scope(Motif).find(params[:id])
  end

  def motif_params
    params.require(:motif).permit(:name, :service_id, :color, :default_duration_in_min, :online, :location_type, :max_booking_delay, :min_booking_delay, :disable_notifications_for_users, :restriction_for_rdv, :instruction_for_rdv, :for_secretariat)
  end
end

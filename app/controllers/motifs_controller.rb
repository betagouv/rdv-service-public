class MotifsController < DashboardAuthController
  respond_to :html, :json

  before_action :set_organisation, only: [:new, :create]
  before_action :set_motif, only: [:edit, :update, :destroy]

  def index
    @motifs = policy_scope(Motif).includes(:organisation).active.includes(:service).order(Arel.sql('LOWER(name)')).page(params[:page])
  end

  def new
    @motif = Motif.new(organisation_id: current_organisation.id)
    authorize(@motif)
    respond_right_bar_with @motif
  end

  def edit
    authorize(@motif)
    respond_right_bar_with @motif
  end

  def create
    @motif = Motif.new(motif_params)
    @motif.organisation = @organisation
    authorize(@motif)
    flash[:notice] = "Motif créé." if @motif.save
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
    params.require(:motif).permit(:name, :service_id, :color, :default_duration_in_min, :online, :by_phone, :max_booking_delay, :min_booking_delay)
  end
end

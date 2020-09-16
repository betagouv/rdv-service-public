class Admin::MotifsController < AgentAuthController
  respond_to :html, :json

  before_action :set_organisation, only: [:new, :create]
  before_action :set_motif, only: [:edit, :update, :destroy]

  def index
    @motifs = policy_scope(Motif).includes(:organisation).active.includes(:service).ordered_by_name.page(params[:page])
  end

  def new
    @motif = Motif.new(organisation_id: current_organisation.id)
    authorize(@motif)
  end

  def edit
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
      redirect_to admin_organisation_motifs_path(@motif.organisation)
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

  def set_motif
    @motif = policy_scope(Motif).find(params[:id])
  end

  def motif_params
    params.require(:motif)
      .permit(:name, :service_id, :color, :default_duration_in_min, :reservable_online, :location_type, :max_booking_delay, :min_booking_delay, :disable_notifications_for_users, :restriction_for_rdv, :instruction_for_rdv, :for_secretariat, :follow_up)
  end
end

class EvenementTypesController < DashboardAuthController
  respond_to :html, :json

  before_action :set_organisation, only: [:index, :new]
  before_action :set_evenement_type, only: [:edit, :update, :destroy]

  def index
    evenement_types = policy_scope(EvenementType).includes(:motif)
    @evenement_types_grouped_by_motif = evenement_types.group_by(&:motif).sort_by { |k, _| k.name }.to_h
  end

  def new
    @evenement_type = EvenementType.new
    authorize(@evenement_type)
    respond_right_bar_with @evenement_type
  end

  def edit
    authorize(@evenement_type)
    respond_right_bar_with @evenement_type
  end

  def create
    @evenement_type = EvenementType.new(evenement_type_params)
    authorize(@evenement_type)
    flash[:notice] = "Type d'événement créé." if @evenement_type.save
    respond_right_bar_with @evenement_type, location: organisation_evenement_types_path(@evenement_type.organisation)
  end

  def update
    authorize(@evenement_type)
    flash[:notice] = "Le type d'événement a été modifié." if @evenement_type.update(evenement_type_params)
    respond_right_bar_with @evenement_type, location: organisation_evenement_types_path(@evenement_type.organisation)
  end

  def destroy
    authorize(@evenement_type)
    @evenement_type.destroy
    redirect_to organisation_evenement_types_path(@evenement_type.motif.organisation), notice: "Le type d'événement a été supprimé."
  end

  private

  def set_evenement_type
    @evenement_type = policy_scope(EvenementType).find(params[:id])
  end

  def evenement_type_params
    params.require(:evenement_type).permit(:name, :motif_id, :color, :accept_multiple_pros, :accept_multiple_users, :at_home, :default_duration_in_min)
  end
end

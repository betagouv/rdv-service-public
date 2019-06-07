class MotifsController < DashboardAuthController
  respond_to :html, :json

  before_action :set_motif, only: [:show, :edit, :update, :destroy]

  def new
    @specialite = policy_scope(Specialite).find(params[:specialite_id])
    @organisation = current_pro.organisation
    @motif = Motif.new(specialite: @specialite)
    authorize(@motif)
    respond_right_bar_with @motif
  end

  def edit
    authorize(@motif)
    respond_right_bar_with @motif
  end

  def create
    @motif = Motif.new(motif_params)
    @motif.specialite = policy_scope(Specialite).find(params[:specialite_id])
    @motif.organisation = current_pro.organisation
    authorize(@motif)
    flash[:notice] = "Motif créé." if @motif.save
    respond_right_bar_with @motif, location: organisation_specialite_path(current_pro.organisation, @motif.specialite)
  end

  def update
    authorize(@motif)
    flash[:notice] = 'Le motif a été modifié.' if @motif.update(motif_params)
    respond_right_bar_with @motif, location: organisation_specialite_path(@organisation, @specialite)
  end

  def destroy
    authorize(@motif)
    @motif.destroy
    redirect_to organisation_specialite_path(@motif.organisation, @motif.specialite), notice: 'Le motif a été supprimé.'
  end

  private

  def set_motif
    @motif = policy_scope(Motif).find(params[:id])
  end

  def motif_params
    params.require(:motif).permit(:name)
  end
end

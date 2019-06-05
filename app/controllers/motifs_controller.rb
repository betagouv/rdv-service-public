class MotifsController < DashboardAuthController
  respond_to :html, :json

  before_action :set_organisation
  before_action :set_specialite
  before_action :set_motif, only: [:show, :edit, :update, :destroy]

  def new
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
    authorize(@motif)

    if @motif.save
      redirect_to organisation_specialite_path(@organisation, @specialite), notice: 'Motif ajouté.'
    else
      respond_right_bar_with @motif, template: :new
    end
  end

  def update
    authorize(@motif)
    if @motif.update(motif_params)
      redirect_to organisation_specialite_path(@organisation, @specialite), notice: 'Le motif a été modifié.'
    else
      respond_right_bar_with @motif, template: :edit
    end
  end

  def destroy
    authorize(@motif)
    @motif.destroy
    redirect_to organisation_specialite_path(@organisation, @specialite), notice: 'Le motif a été supprimé.'
  end

  private

  def set_organisation
    @organisation = policy_scope(Organisation).find(params[:organisation_id])
  end

  def set_specialite
    @specialite = policy_scope(Specialite).find(params[:specialite_id])
  end

  def set_motif
    @motif = policy_scope(Motif).find(params[:id])
  end

  def motif_params
    params.require(:motif).permit(:name, :specialite_id)
  end
end

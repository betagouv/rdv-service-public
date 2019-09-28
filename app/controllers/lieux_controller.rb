class LieuxController < DashboardAuthController
  respond_to :html, :json

  def index
    @lieux = policy_scope(Lieu).order(Arel.sql('LOWER(name)')).page(params[:page])
  end

  def new
    @lieu = Lieu.new(organisation_id: current_pro.organisation_id)
    authorize(@lieu)
    respond_right_bar_with @lieu
  end

  def create
    @lieu = Lieu.new(organisation_id: current_pro.organisation_id)
    @lieu.assign_attributes(lieu_params)
    authorize(@lieu)
    flash.notice = "Lieu créé" if @lieu.save
    respond_right_bar_with @lieu, location: lieux_path
  end

  def edit
    @lieu = policy_scope(Lieu).find(params[:id])
    authorize(@lieu)
    respond_right_bar_with @lieu
  end

  def update
    @lieu = Lieu.find(params[:id])
    authorize(@lieu)
    flash[:notice] = 'Lieu modifié' if @lieu.update(lieu_params)
    respond_right_bar_with @lieu, location: lieux_path
  end

  def destroy
    @lieu = Lieu.find(params[:id])
    authorize(@lieu)
    flash[:notice] = 'Lieu supprimé' if @lieu.destroy
    respond_right_bar_with @lieu, location: lieux_path
  end

  private

  def lieu_params
    params.require(:lieu).permit(:name, :address, :horaires, :telephone)
  end
end

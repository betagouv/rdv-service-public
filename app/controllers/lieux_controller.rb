class LieuxController < DashboardAuthController
  respond_to :html, :json

  def index
    @lieux = policy_scope(Lieu).includes(:organisation).order(Arel.sql('LOWER(name)')).page(params[:page])
  end

  def new
    @lieu = Lieu.new(organisation_id: current_organisation.id)
    authorize(@lieu)
    respond_right_bar_with @lieu
  end

  def create
    @lieu = Lieu.new(organisation_id: current_organisation.id)
    @lieu.assign_attributes(lieu_params)
    authorize(@lieu)
    flash.notice = "Le lieu a été créé." if @lieu.save
    respond_right_bar_with @lieu, location: organisation_lieux_path(@lieu.organisation)
  end

  def edit
    @lieu = policy_scope(Lieu).find(params[:id])
    authorize(@lieu)
    respond_right_bar_with @lieu
  end

  def update
    @lieu = Lieu.find(params[:id])
    authorize(@lieu)
    flash[:notice] = 'Lieu a été modifié.' if @lieu.update(lieu_params)
    respond_right_bar_with @lieu, location: organisation_lieux_path(@lieu.organisation)
  end

  def destroy
    @lieu = Lieu.find(params[:id])
    authorize(@lieu)
    flash[:notice] = 'Le lieu a été supprimé.' if @lieu.destroy
    respond_right_bar_with @lieu, location: organisation_lieux_path(@lieu.organisation)
  end

  private

  def lieu_params
    params.require(:lieu).permit(:name, :address, :horaires, :telephone)
  end
end

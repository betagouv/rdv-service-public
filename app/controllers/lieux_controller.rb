class LieuxController < DashboardAuthController
  respond_to :html, :json

  before_action :set_organisation

  def new
    @lieu = Lieu.new(organisation: @organisation)
    authorize(@lieu)
    respond_right_bar_with @lieu
  end

  def create
    @lieu = Lieu.new(organisation: @organisation)
    @lieu.assign_attributes(lieu_params)
    authorize(@lieu)
    flash.notice = "Lieu créé" if @lieu.save
    respond_right_bar_with @lieu, location: @lieu.organisation
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
    respond_right_bar_with @lieu, location: @lieu.organisation
  end

  def destroy
    @lieu = Lieu.find(params[:id])
    authorize(@lieu)
    if @lieu.destroy
      redirect_to @lieu.organisation, notice: 'Lieu supprimé'
    else
      render :edit
    end
  end

  private

  def lieu_params
    params.require(:lieu).permit(:name, :address, :horaires, :telephone)
  end
end

class Admin::LieuxController < AgentAuthController
  respond_to :html, :json

  def index
    @lieux = policy_scope(Lieu).includes(:organisation).ordered_by_name.page(params[:page])
  end

  def new
    @lieu = Lieu.new(organisation_id: current_organisation.id)
    authorize(@lieu)
  end

  def create
    @lieu = Lieu.new(organisation_id: current_organisation.id)
    @lieu.assign_attributes(lieu_params)
    authorize(@lieu)
    if @lieu.save
      flash.notice = "Le lieu a été créé."
      redirect_to admin_organisation_lieux_path(@lieu.organisation)
    else
      render :new
    end
  end

  def edit
    @lieu = policy_scope(Lieu).find(params[:id])
    authorize(@lieu)
  end

  def update
    @lieu = Lieu.find(params[:id])
    authorize(@lieu)
    if @lieu.update(lieu_params)
      flash[:notice] = "Lieu a été modifié."
      redirect_to admin_organisation_lieux_path(@lieu.organisation)
    else
      render :edit
    end
  end

  def destroy
    @lieu = Lieu.find(params[:id])
    authorize(@lieu)
    if @lieu.destroy
      flash[:notice] = "Le lieu a été supprimé."
      redirect_to admin_organisation_lieux_path(@lieu.organisation)
    else
      render :edit
    end
  end

  private

  def lieu_params
    params.require(:lieu).permit(:name, :address, :phone_number, :enabled, :latitude, :longitude)
  end
end

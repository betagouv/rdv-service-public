class Admin::LieuxController < AgentAuthController
  respond_to :html, :json

  def index
    @lieux = policy_scope(Lieu, policy_scope_class: Agent::LieuPolicy::Scope)
      .where(organisation: current_organisation)
      .not_single_use
      .ordered_by_name
      .page(params[:page])
    @lieux_policy = Agent::LieuPolicy.new(current_agent, Lieu.new(organisation: current_organisation))
  end

  def new
    @lieu = Lieu.new(organisation_id: current_organisation.id)
    authorize(@lieu, policy_class: Agent::LieuPolicy)
  end

  def create
    @lieu = Lieu.new(organisation_id: current_organisation.id)
    @lieu.assign_attributes(lieu_params)
    @lieu.availability = :enabled # Always enable new Lieux

    authorize(@lieu, policy_class: Agent::LieuPolicy)
    if @lieu.save
      flash.notice = "Le lieu a été créé."
      redirect_to admin_organisation_lieux_path(@lieu.organisation)
    else
      render :new
    end
  end

  def edit
    @lieu = policy_scope(Lieu, policy_scope_class: Agent::LieuPolicy::Scope).where(organisation: current_organisation).find(params[:id])
    authorize(@lieu, policy_class: Agent::LieuPolicy)
  end

  def update
    @lieu = Lieu.find(params[:id])
    authorize(@lieu, policy_class: Agent::LieuPolicy)
    if @lieu.update(lieu_params)
      flash[:notice] = "Le lieu a été modifié."
      redirect_to admin_organisation_lieux_path(@lieu.organisation)
    else
      render :edit
    end
  end

  def destroy
    @lieu = Lieu.find(params[:id])
    authorize(@lieu, policy_class: Agent::LieuPolicy)
    if @lieu.destroy
      flash[:notice] = "Le lieu a été supprimé."
      redirect_to admin_organisation_lieux_path(@lieu.organisation)
    else
      render :edit
    end
  end

  private

  def pundit_user
    current_agent
  end

  def lieu_params
    params.require(:lieu).permit(:name, :address, :phone_number, :enabled, :latitude, :longitude)
  end
end

class Admin::RdvPlansController < AgentAuthController
  def new
    # TODO: gérer les scopes sur le user et motif (probablement dans la policy)
    @rdv_plan = RdvPlan.new(planning_agent: current_agent, motif_id: params[:motif_id], lieu_id: params[:lieu_id], user_id: params[:user_id])

    authorize(@rdv_plan, policy_class: Agent::RdvPlanPolicy)
  end

  def create
    # TODO: gérer les scopes sur le user et motif (probablement dans la policy)

    @rdv_plan = RdvPlan.new(create_params.merge(planning_agent: current_agent))

    authorize(@rdv_plan, policy_class: Agent::RdvPlanPolicy)

    if @rdv_plan.save
      @rdv_plan.generate_invitation_token!

      redirect_to admin_organisation_rdv_plan_path(current_organisation, @rdv_plan)
    else
      render :new
    end
  end

  def show
    @rdv_plan = RdvPlan.find(params[:id])
    authorize(@rdv_plan, policy_class: Agent::RdvPlanPolicy)
  end

  private

  def create_params
    params.require(:rdv_plan).permit(:motif_id, :user_id, :lieu_id)
  end

  def pundit_user
    current_agent
  end
end

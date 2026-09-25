class Admin::RdvPlansController < AgentAuthController
  layout "application_agent"

  def new
    @rdv_plan = RdvPlan.new(planning_agent: current_agent, rdv_agent_id: params[:agent_id])
    authorize(@rdv_plan, policy_class: Agent::RdvPlanPolicy)
  end

  def create
    rdv_plan_params = params.require(:rdv_plan).permit(:rdv_agent_id, :user_id)

    rdv_plan = RdvPlan.new(rdv_plan_params.merge(planning_agent: current_agent))

    user = rdv_plan.user

    if user.blank?
      user = User.new(params.require(:rdv_plan).require(:user).permit(:first_name, :last_name, :email, :phone_number))
      user.user_profiles.build(organisation: current_organisation)

      authorize(user, :create?, policy_class: Agent::UserPolicy)

      user.save!
      rdv_plan.user_id = user.id
    end

    authorize(rdv_plan, policy_class: Agent::RdvPlanPolicy)

    # TODO: wrap in a transaction
    rdv_plan.save!
    redirect_to edit_motif_agents_rdv_plan_path(rdv_plan, organisation_id: params[:organisation_id])
  end

  private

  def pundit_user
    current_agent
  end
end

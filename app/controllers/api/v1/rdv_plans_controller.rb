class Api::V1::RdvPlansController < Api::V1::AgentAuthBaseController
  def create
    rdv_plan = RdvPlan.transaction do
      user = User.find_or_create_by(params.require(:user).permit(:first_name, :last_name, :phone_number))

      RdvPlan.create!(
        planning_agent: current_agent,
        user: user
      )
    end
    render_record rdv_plan
  end

  def show
    rdv_plan = policy_scope(RdvPlan, policy_scope_class: Agent::RdvPlanPolicy::Scope).find(params[:id])

    render_record rdv_plan
  end
end

class Api::V1::RdvPlansController < Api::V1::AgentAuthBaseController
  def create
    rdv_plan = RdvPlan.transaction do
      user_params = params.require(:user)

      user = User.find_by(user_params.permit(:email))

      user ||= User.find_by(user_params.permit(:first_name, :last_name, :phone_number))

      user ||= User.new(user_params.permit(:first_name, :last_name, :phone_number).merge(created_through: :agent_creation))

      user.skip_confirmation_notification!
      user.update!(user_params.permit(:email, :address))

      RdvPlan.create!(
        planning_agent: current_agent,
        user: user,
        return_url: params[:return_url]
      )
    end
    json = RdvPlanBlueprint.render_as_hash(rdv_plan, root: "rdv_plan")
    json["url"] = admin_organisation_agent_agenda_url(
      current_agent.organisations.first.id,
      current_agent.id,
      host: ENV["HOST"],
      user_ids: [rdv_plan.user.id],
      rdv_plan_id: rdv_plan.id
    )
    render json:, status: :created
  end

  def show
    rdv_plan = policy_scope(RdvPlan, policy_scope_class: Agent::RdvPlanPolicy::Scope).find(params[:id])

    render_record rdv_plan
  end
end

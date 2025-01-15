class Agents::RdvPlansController < AgentAuthController
  layout "application"
  before_action :find_rdv_plan, except: [:create]

  # juste pour la démo
  def create
    user_id = params.dig(:rdv_plan, :user_id)
    rdv_plan = RdvPlan.create!(
      planning_agent: current_agent,
      user_id: user_id,
      return_url: request.referer
    )
    authorize rdv_plan, :create?, policy_class: Agent::RdvPlanPolicy
    redirect_to admin_organisation_agent_agenda_path(
      current_agent.organisations.first.id,
      current_agent.id,
      user_ids: [user_id],
      rdv_plan_id: rdv_plan.id
    )
  end

  private

  def find_rdv_plan
    @rdv_plan = current_agent.rdv_plans.find(params[:id])
    authorize @rdv_plan, :edit?, policy_class: Agent::RdvPlanPolicy
  end

  def pundit_user
    current_agent
  end
end

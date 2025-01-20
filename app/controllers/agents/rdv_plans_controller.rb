class Agents::RdvPlansController < AgentAuthController
  layout "application"
  before_action :find_rdv_plan

  def show
    redirect_to edit_starts_at_agents_rdv_plan_path(@rdv_plan)
  end

  def edit_starts_at
    @rdv_plan.starts_at = nil
  end

  def update_starts_at
    @rdv_plan.update!(params.require(:rdv_plan).permit(:starts_at).merge(rdv_agent: current_agent))
    redirect_to show_starts_at_agents_rdv_plan_path(@rdv_plan)
  end

  def show_starts_at; end

  private

  def find_rdv_plan
    @rdv_plan = RdvPlan.find(params[:id])
    authorize @rdv_plan, :edit?, policy_class: Agent::RdvPlanPolicy
  end

  def pundit_user
    current_agent
  end
end

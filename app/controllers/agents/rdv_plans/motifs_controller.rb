class Agents::RdvPlans::MotifsController < AgentAuthController
  layout "application"
  before_action :find_rdv_plan

  def create
    @motif = Motif.new(params.require(:motif).permit(:name, :default_duration_in_min, :location_type))

    @motif.organisation = current_agent.admin_orgs.first

    authorize(@motif, policy_class: Agent::MotifPolicy)

    if @motif.save
      @rdv_plan.update!(motif_id: @motif.id)
      redirect_to edit_starts_at_agents_rdv_plan_path(@rdv_plan)
    else
      render "agents/rdv_plans/edit_motif"
    end
  end

  private

  def find_rdv_plan
    @rdv_plan = RdvPlan.find(params[:id])
    authorize @rdv_plan, :edit?, policy_class: Agent::RdvPlanPolicy
  end

  def pundit_user
    current_agent
  end
end

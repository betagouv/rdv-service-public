class Agents::RdvPlansController < AgentAuthController
  layout "application"

  def new
    motif
  end

  def create
    update_motif
  end

  def motif
    @rdv_plan = current_agent.rdv_plans.new
    authorize @rdv_plan, :edit?, policy_class: Agent::RdvPlanPolicy
    render "motif"
  end

  def update_motif
    @rdv_plan = RdvPlan.find_by(id: params[:id]) || RdvPlan.new(rdv_plans_params)
    authorize @rdv_plan, :edit?, policy_class: Agent::RdvPlanPolicy
    @rdv_plan.assign_attributes(agent: current_agent)
    if @rdv_plan.save
      redirect_to creneau_agents_rdv_plan_path(@rdv_plan)
    else
      render "motif"
    end
  end

  def creneau
    @rdv_plan = current_agent.rdv_plans.find(params[:id])
    authorize @rdv_plan, :edit?, policy_class: Agent::RdvPlanPolicy
    @next_availabilities = if @rdv_plan.motif.individuel?
                             CreneauxSearch::ForAgent.new(@rdv_plan).next_availabilities
                           else
                             CreneauxSearch::RdvCollectifForAgent.new(@rdv_plan).next_availabilities
                           end

    render "creneau"
  end

  def update
    @rdv_plan = current_agent.rdv_plans.find(params[:id])
    authorize @rdv_plan, :edit?, policy_class: Agent::RdvPlanPolicy

    if @rdv_plan.update(rdv_plans_params)
      if @rdv_plan.confirmed?
        rdv = @rdv_plan.rdv

        redirect_to admin_organisation_rdv_path(rdv, rdv.organisation)
      else
        redirect_to agents_rdv_plan_edit_path(@rdv_plan)
      end
    else
      render "edit"
    end
  end

  private

  def pundit_user
    current_agent
  end

  def rdv_plans_params
    params.require(:rdv_plan).permit(:motif_id)
  end
end

class Agents::RdvPlansController < AgentAuthController
  layout "application"

  def new
    @rdv_plan = current_agent.rdv_plans.new
    authorize @rdv_plan, :edit?, policy_class: Agent::RdvPlanPolicy
    render "motif"
  end

  def create
    update_motif
  end

  def motif
    find_rdv_plan
  end

  def update_motif
    @rdv_plan = RdvPlan.find_by(id: params[:id]) || RdvPlan.new
    authorize @rdv_plan, :edit?, policy_class: Agent::RdvPlanPolicy

    if @rdv_plan.update(params.require(:rdv_plan).permit(:motif_id).merge(agent: current_agent))
      redirect_to lieu_agents_rdv_plan_path(@rdv_plan)
    else
      render "motif"
    end
  end

  def lieu
    find_rdv_plan
    @rdv_plan.lieu_id = nil
    @next_availabilities = if @rdv_plan.motif.individuel?
                             CreneauxSearch::ForAgent.new(@rdv_plan).next_availabilities
                           else
                             CreneauxSearch::RdvCollectifForAgent.new(@rdv_plan).next_availabilities
                           end
  end

  def update_lieu
    find_rdv_plan
    if @rdv_plan.update(params.require(:rdv_plan).permit(:lieu_id))
      redirect_to creneau_agents_rdv_plan_path(@rdv_plan)
    else
      render "lieu"
    end
  end

  def creneau
    find_rdv_plan

    @results = if @rdv_plan.motif.individuel?
                 CreneauxSearch::ForAgent.new(@rdv_plan).build_result
               else
                 CreneauxSearch::RdvCollectifForAgent.new(@rdv_plan).slot_search
               end
  end

  def update_creneau
    find_rdv_plan
    if @rdv_plan.update(params.require(:rdv_plan).permit(:starts_at, :rdv_agent_id))
      redirect_to user_agents_rdv_plan_path(@rdv_plan)
    else
      render "creneau"
    end
  end

  def user
    find_rdv_plan
  end

  def update_user
    find_rdv_plan
  end

  def notifications
    find_rdv_plan
  end

  def create_rdv
    find_rdv_plan
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

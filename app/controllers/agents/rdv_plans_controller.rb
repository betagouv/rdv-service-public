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
    redirect_to edit_modalites_agents_rdv_plan_path(@rdv_plan)
  end

  def edit_modalites; end

  def update_modalites
    rdv_plan_params = params.require(:rdv_plan)

    location_type, lieu_id = rdv_plan_params["modalite"].split("-")

    @rdv_plan.assign_attributes(
      location_type: location_type,
      lieu_id: lieu_id
    )
    @rdv_plan.assign_attributes(rdv_plan_params.permit(:starts_at))

    if @rdv_plan.save
      redirect_to edit_motif_agents_rdv_plan_path(@rdv_plan)
    else
      render "edit_modalites"
    end
  end

  def edit_motif
    @motifs = current_agent.motifs.individuel.where(
      organisation_id: current_agent.roles.select(:organisation_id),
      location_type: @rdv_plan.location_type,
      service: @rdv_plan.rdv_agent.services
    )
    @rdv_plan.duration_in_minutes ||= @motifs.first.default_duration_in_min
  end

  def update_motif
    if @rdv_plan.update(params.require(:rdv_plan).permit(:motif_id, :duration_in_minutes))
      redirect_to edit_user_agents_rdv_plan_path(@rdv_plan)
    else
      render "edit_motif_from_calendar"
    end
  end

  def edit_user; end

  private

  def find_rdv_plan
    @rdv_plan = RdvPlan.find(params[:id])
    authorize @rdv_plan, :edit?, policy_class: Agent::RdvPlanPolicy
  end

  def pundit_user
    current_agent
  end
end

class Agents::RdvPlans::LieuxController < AgentAuthController
  layout "application"
  before_action :find_rdv_plan

  def create
    @lieu = Lieu.new(lieu_params)

    @lieu.organisation = current_agent.admin_orgs.first

    authorize(@lieu, policy_class: Agent::LieuPolicy)

    if @lieu.save
      @rdv_plan.update!(lieu_id: @lieu.id)
      redirect_to edit_user_agents_rdv_plan_path(@rdv_plan)
    else
      render "agents/rdv_plans/edit_lieu"
    end
  end

  private

  def lieu_params
    params.require(:lieu).permit(:name, :address, :phone_number, :enabled, :latitude, :longitude, :address_without_geocoding)
  end

  def find_rdv_plan
    @rdv_plan = RdvPlan.find(params[:id])
    authorize @rdv_plan, :edit?, policy_class: Agent::RdvPlanPolicy
  end

  def pundit_user
    current_agent
  end
end

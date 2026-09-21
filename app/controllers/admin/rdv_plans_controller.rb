class Admin::RdvPlansController < AgentAuthController
  include RdvPlansControllerActions
  layout "application_agent"

  before_action :find_rdv_plan, except: [:create]
  before_action :redirect_to_rdv, if: -> { @rdv_plan&.rdv.present? }, except: %i[rdv create]
  before_action do
    @hide_rdv_plan_banner = true
  end

  def create
    rdv_plan = RdvPlan.new(planning_agent: current_agent, rdv_agent_id: params[:agent_id], user: current_organisation.users.last)
    authorize(rdv_plan, policy_class: Agent::RdvPlanPolicy)

    rdv_plan.save!
    redirect_to edit_motif_admin_organisation_rdv_plan_path(current_organisation, rdv_plan)
  end
end

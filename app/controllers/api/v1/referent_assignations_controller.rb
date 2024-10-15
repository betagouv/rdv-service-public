class Api::V1::ReferentAssignationsController < Api::V1::AgentAuthBaseController
  def create
    referent_assignation = ReferentAssignation.new(referent_assignation_params)
    authorize(referent_assignation, policy_class: Agent::ReferentAssignationPolicy)
    referent_assignation.save!
    render_record referent_assignation
  end

  def destroy
    referent_assignation = ReferentAssignation.find_by!(referent_assignation_params)
    authorize(referent_assignation, policy_class: Agent::ReferentAssignationPolicy)
    referent_assignation.destroy!
    head :no_content
  end

  private

  def referent_assignation_params
    params.permit(:agent_id, :user_id)
  end
end

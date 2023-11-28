class Api::V1::ReferentAssignationsController < Api::V1::AgentAuthBaseController
  def create
    referent_assignation = ReferentAssignation.new(referent_assignation_params)
    authorize(referent_assignation)
    referent_assignation.save!
    render_record referent_assignation
  end

  def upsert_many
    create_referent_assignations
    user = User.find(referent_assignations_params[:user_id])
    render_record user, agent_context: pundit_user
  rescue StandardError => e
    render_error :unprocessable_entity, { success: false, errors: {}, error_messages: [e] }
  end

  def destroy
    referent_assignation = ReferentAssignation.find_by!(referent_assignation_params)
    authorize(referent_assignation)
    referent_assignation.destroy!
    head :no_content
  end

  private

  def create_referent_assignations
    referent_assignations_params[:agent_ids].each do |agent_id|
      referent_assignation =
        ReferentAssignation.find_or_initialize_by(referent_assignations_params.except(:agent_ids).merge(agent_id: agent_id))
      begin
        authorize(referent_assignation)
        referent_assignation.save
      rescue Pundit::NotAuthorizedError
        next # we don't want to block the whole request if some assignations are not authorized
      end
    end
  end

  def referent_assignations_params
    params.permit(:user_id, agent_ids: []).to_h.symbolize_keys
  end

  def referent_assignation_params
    params.permit(:user_id, :agent_id)
  end
end

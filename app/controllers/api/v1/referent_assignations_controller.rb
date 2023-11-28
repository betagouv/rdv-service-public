class Api::V1::ReferentAssignationsController < Api::V1::AgentAuthBaseController
  before_action :set_user, only: %i[create_many]

  def create
    referent_assignation = ReferentAssignation.new(referent_assignation_params)
    authorize(referent_assignation)
    referent_assignation.save!
    render_record referent_assignation
  end

  def create_many
    referent_assignations_params[:agent_ids].each do |agent_id|
      referent_assignation =
        ReferentAssignation.find_or_initialize_by(user: @user, agent_id: agent_id)
      begin
        authorize(referent_assignation)
        referent_assignation.save
      rescue Pundit::NotAuthorizedError
        next # we don't want to block the whole request if some assignations are not authorized
      end
    end
    head :ok
  end

  def destroy
    referent_assignation = ReferentAssignation.find_by!(referent_assignation_params)
    authorize(referent_assignation)
    referent_assignation.destroy!
    head :no_content
  end

  private

  def set_user
    @user = User.find(referent_assignations_params[:user_id])
  rescue ActiveRecord::RecordNotFound
    render_error :not_found, not_found: :user
  end

  def referent_assignations_params
    params.permit(:user_id, agent_ids: []).to_h.symbolize_keys
  end

  def referent_assignation_params
    params.permit(:user_id, :agent_id)
  end
end

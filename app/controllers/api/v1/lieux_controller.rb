class Api::V1::LieuxController < Api::V1::AgentAuthBaseController
  def create
    lieu = Lieu.new(params.permit(:organisation_id, :name, :address, :latitude, :longitude, :phone_number))

    authorize(lieu, policy_class: Agent::LieuPolicy)

    if lieu.save
      render json: LieuBlueprint.render(lieu)
    else
      render status: :unprocessable_entity, json: { error_messages: lieu.errors.full_messages }
    end
  end

  private

  def pundit_user
    current_agent
  end
end

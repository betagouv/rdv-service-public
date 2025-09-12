class Api::V1::LieuxController < Api::V1::AgentAuthBaseController
  def create
    lieu = Lieu.new(params.permit(:organisation_id, :name, :address, :latitude, :longitude, :phone_number))

    authorize(lieu, policy_class: Agent::LieuPolicy)

    external_reference_params = params[:external_reference]

    if external_reference_params.present?
      @external_reference = ExternalReference.new(
        params.require(:external_reference).permit(:external_id, :external_url).merge(
          item: lieu,
          oauth_application: doorkeeper_token&.application,
          territory_id: lieu.organisation.territory_id
        )
      )
    end

    lieu.transaction do
      lieu.save && @external_reference&.save!
    end

    if lieu.persisted?
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

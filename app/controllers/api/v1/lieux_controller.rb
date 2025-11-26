class Api::V1::LieuxController < Api::V1::AgentAuthBaseController
  def index
    lieux = policy_scope(Lieu, policy_scope_class: Agent::LieuPolicy::Scope)
      .where(availability: "enabled")
    render_collection(lieux.order(:id))
  end

  def create
    lieu = Lieu.new(params.permit(:organisation_id, :name, :address, :latitude, :longitude, :phone_numberm, :availability))

    authorize(lieu, policy_class: Agent::LieuPolicy)

    lieu.transaction do
      lieu.save

      if params[:external_reference].present?
        ExternalReference.create!(
          params.require(:external_reference).permit(:external_id, :external_url).merge(
            item: lieu,
            oauth_application: doorkeeper_token&.application,
            territory_id: lieu.organisation.territory_id
          )
        )
      end
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

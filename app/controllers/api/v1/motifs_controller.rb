class Api::V1::MotifsController < Api::V1::AgentAuthBaseController
  def index
    motifs = policy_scope(current_organisation.motifs, policy_scope_class: Agent::MotifPolicy::Scope)
    motifs = motifs.active(params[:active].to_b) unless params[:active].nil?

    if params.key?(:bookable_publicly)
      motifs = if params[:bookable_publicly].to_b
                 motifs.bookable_by_everyone_or_bookable_by_invited_users
               else
                 motifs.not_bookable_by_everyone_or_not_bookable_by_invited_users
               end
    end

    if params.key?(:service_id) # Il est possible de filtrer les motifs sans service
      motifs = motifs.where(service_id: params[:service_id].presence)
    end

    motifs = motifs.with_motif_category_short_name(@params[:motif_category_short_name]) if params[:motif_category_short_name].present?

    render_collection(motifs.order(:id))
  end

  def create
    if params[:external_reference].present?
      @external_reference = ExternalReference.find_or_initialize_by(
        params.require(:external_reference).permit(:external_id, :external_url).merge(
          oauth_application: doorkeeper_token&.application,
          item_type: "Motif",
          territory_id: Organisation.find(params[:organisation_id]).territory_id
        )
      )

      if @external_reference
        render(json: { object: MotifBlueprint.render_as_hash(@external_reference.item), warning: "Un objet existe déjà pour cet external_id." }) and return
      end
    end

    motif = Motif.new(params.permit(*motif_attribute_names))

    authorize(motif, policy_class: Agent::MotifPolicy)

    motif.transaction do
      motif.save!
      @external_reference&.update!(item: motif)
    end

    if motif.persisted?
      render json: MotifBlueprint.render(motif)
    else
      render status: :unprocessable_entity, json: { error_messages: motif.errors.full_messages }
    end
  end

  private

  def motif_attribute_names
    InstanceExport::MOTIF_ATTRIBUTE_NAMES + [:organisation_id]
  end

  def pundit_user
    current_agent
  end
end

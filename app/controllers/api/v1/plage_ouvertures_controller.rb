class Api::V1::PlageOuverturesController < Api::V1::AgentAuthBaseController
  def create # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    plage_ouverture = PlageOuverture.new(create_params)

    # On ne documente pas encore la possibilité d'utiliser le param recurrence, puisqu'on s'en sert uniquement
    # pour la migration des Conseillers Numériques, et que l'api actuelle permettrait de créer des absences qu'on
    # ne saurait pas gérer sur l'interface web avec le formulaire actuel.
    if params[:recurrence].present?
      plage_ouverture.recurrence = Montrose::Recurrence.load(params[:recurrence])
    end

    if params[:lieu_external_id].present?
      plage_ouverture.lieu_id = external_reference_scope.find_by(item_type: "Lieu", external_id: params[:lieu_external_id])&.item_id

      if plage_ouverture.lieu_id.nil?
        render status: :not_found, json: { error_messages: ["Aucun lieu trouvé pour le lieux_external_id #{params[:lieu_external_id]}"] }
        return
      end
    end

    if params[:motif_external_ids].present?
      plage_ouverture.motif_ids = external_reference_scope.where(item_type: "Motif", external_id: params[:motif_external_ids]).pluck(:item_id)

      if plage_ouverture.motif_ids.count != params[:motif_external_ids].count
        render status: :not_found, json: { error_messages: ["Certains motifs n'ont pas été trouvés pour les motif_external_ids #{params[:motif_external_ids].join(', ')}"] }
        return
      end

    end

    authorize(plage_ouverture, policy_class: Agent::PlageOuverturePolicy)
    plage_ouverture.transaction do
      plage_ouverture.save!

      if params[:external_reference].present?
        ExternalReference.create!(
          params.require(:external_reference).permit(:external_id, :external_url).merge(
            item: plage_ouverture,
            oauth_application: doorkeeper_token&.application
          )
        )
      end
    end

    if plage_ouverture.persisted?
      render json: PlageOuvertureBlueprint.render(plage_ouverture)
    else
      render status: :unprocessable_entity, json: { error_messages: plage_ouverture.errors.full_messages }
    end
  rescue ActiveRecord::RecordNotFound
    render_error :not_found, not_found: :agent
  end

  private

  def create_params
    # Allow creating an plage_ouverture for an agent identified by their email.
    if params[:agent_id].blank? && params[:agent_email].present?
      agent = Agent.find_by!(email: params[:agent_email])
      render_error :not_found, not_found: :agent unless agent
      params[:agent_id] = agent.id
      params.delete(:agent_email)
    end

    params[:agent_id] ||= current_agent.id

    params.permit(:agent_id, :title, :first_day, :start_time, :end_day, :end_time, :organisation_id)
  end

  def external_reference_scope
    @external_reference_scope ||= Agent::ExternalReferencePolicy::Scope.new(
      current_agent,
      ExternalReference.where(oauth_application_id: doorkeeper_token.application_id)
    ).resolve
  end
end

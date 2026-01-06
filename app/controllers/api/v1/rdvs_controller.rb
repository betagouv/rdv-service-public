class Api::V1::RdvsController < Api::V1::AgentAuthBaseController
  before_action :normalize_array_params, only: %i[index]

  def index # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    rdvs = policy_scope(Rdv, policy_scope_class: Agent::RdvPolicy::Scope).where(params.permit(:organisation_id))

    rdvs = rdvs.starts_after(Time.zone.parse(params[:starts_after])) if params[:starts_after].present?
    rdvs = rdvs.starts_before(Time.zone.parse(params[:starts_before])) if params[:starts_before].present?

    if params[:include].nil?
      rdvs = rdvs.includes(:organisation, :lieu, :agents, :users, participations: [:user], motif: [:motif_category])
    elsif params[:include].is_a?(Array)
      rdvs.includes(:organisation) if "organisation".in?(params[:include])

      rdvs.includes(:lieu) if "lieu".in?(params[:include])

      rdvs.includes(:agents) if "agents".in?(params[:include])

      rdvs.includes(:users) if "users".in?(params[:include])

      rdvs.includes(participations: [:user]) if "participations".in?(params[:include])

      rdvs.includes(motif: [:motif_category]) if "motif".in?(params[:include])
    end

    if params[:id].present?
      rdvs = rdvs.where(id: params[:id])
    end

    if params[:user_id].present?
      rdvs = rdvs.includes(participations: [:user]).where(participations: { user_id: params[:user_id] })
    end

    if params[:agent_id].present?
      rdvs = rdvs.where(agents: { id: params[:agent_id] })
    end

    if params[:status].present?
      rdvs = rdvs.where(status: params[:status])
    end

    render_collection(rdvs, options: params.permit(include: []))
  end

  # Cet endpoint est utilisé seulement pour la copie des données d'une instance à l'autre, il n'est donc pas documenté.
  def create # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    # On crée le rendez-vous via ActiveRecord sans lancer les Notifiers, ce qui évite de déclencher des callbacks de notifications pour les agents et les usager
    rdv = Rdv.new(
      params.permit(%w[starts_at status cancelled_at context ends_at name max_participants_count])
    )

    if rdv.starts_at > Time.zone.now
      raise "Cet endpoint ne doit pas être utilisé pour créer des rendez-vous à venir"
    end

    Rdv.transaction do
      oauth_application = doorkeeper_token&.application

      rdv.lieu_id = ExternalReference.find_by(item_type: "Lieu", external_id: params[:lieu_external_id], oauth_application:)&.item_id
      rdv.motif_id = ExternalReference.find_by(item_type: "Motif", external_id: params[:motif_external_id], oauth_application:)&.item_id
      rdv.organisation_id = rdv.motif.organisation_id

      rdv.agents = Agent.where(email: params[:agent_emails])

      rdv.created_by = if params[:created_by_type] == "User"
                         # On peut uniquement utiliser cette logique pour les users parce qu'on n'a pas d'external_ids sur les agents ou les prescripteurs
                         ExternalReference.find_by(item_type: params[:created_by_type], external_id: params[:created_by_external_id], oauth_application:)&.item
                       else
                         # Il faut un created_by sur le rendez-vous pour initialiser les created_by des participations
                         # Mais le champs n'est pas utilisé à part pour envoyer des notifications (ce qu'on ne fait pas ici)
                         # ou identifier un prescripteur, ce qui n'est pas très utile pour les rendez-vous passés.
                         # On peut donc se permettre de faire l'approximation que c'est l'agent du rendez-vous qui l'a créé.
                         #
                         #
                         # Ça permet d'éviter d'avoir à copier les informations des prescripteurs (pour le moment).
                         rdv.agents.first
                       end

      authorize(rdv, :update?, policy_class: Agent::RdvPolicy)

      if rdv.collectif?
        rdv.save!

        params[:participations].each do |participation_params|
          Participation.create(
            rdv: rdv,
            user_id: ExternalReference.find_by(item_type: "User", external_id: participation_params[:user_external_id], oauth_application:)&.item_id,
            status: participation_params[:status],
            created_by: rdv.created_by
          )
        end
      else
        user_external_ids = params[:participations].map { |p| p[:user_external_id] }
        rdv.user_ids = ExternalReference.where(item_type: "User", external_id: user_external_ids, oauth_application:).map(&:item_id)
        rdv.save!
      end

      if params[:external_reference].present?
        ExternalReference.create!(
          params.require(:external_reference).permit(:external_id, :external_url).merge(
            item: rdv,
            oauth_application:
          )
        )
      end
    end

    render json: RdvBlueprint.render(rdv)
  end

  def update_status
    @rdv = Rdv.find(params[:rdv_id])
    authorize(@rdv, :update?, policy_class: Agent::RdvPolicy)

    @rdv.update!(params.permit(:status))

    # Le blueprint complet du rendez-vous renvoie énormément d'information, qui ne sont pas pertinentes ici.
    # On va sans doute devoir restreindre la quantité de données renvoyées par ce blueprint pour rendre
    # l'index de ce controller plus rapide.
    # Pour éviter de devoir investiguer quels clients de l'api dépendent des attributs de ce
    # blueprint pour cet endpoint d'update, on ne renvoie que le statut (ce qui répond à notre besoin).
    render json: @rdv.attributes.symbolize_keys.slice(:status)
  end

  private

  def normalize_array_params
    %i[id status include].each do |param_name|
      if params[param_name].is_a?(String)
        params[param_name] = params[param_name].split(",")
      end
    end
  end

  def pundit_user
    current_agent
  end
end

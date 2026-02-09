class Api::V1::RdvsController < Api::V1::AgentAuthBaseController
  before_action :normalize_array_params, only: %i[index]

  def index # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    rdvs = policy_scope(Rdv, policy_scope_class: Agent::RdvPolicy::Scope).where(params.permit(:organisation_id))

    rdvs = rdvs.starts_after(Time.zone.parse(params[:starts_after])) if params[:starts_after].present?
    rdvs = rdvs.starts_before(Time.zone.parse(params[:starts_before])) if params[:starts_before].present?

    if params[:include].nil?
      rdvs = rdvs.includes(:organisation, :lieu, :agents, :users, participations: [:user], motif: [:motif_category])
    elsif params[:include].is_a?(Array)
      rdvs.includes!(:organisation) if "organisation".in?(params[:include])

      rdvs.includes!(:lieu) if "lieu".in?(params[:include])

      rdvs.includes!(:agents) if "agents".in?(params[:include])

      rdvs.includes!(:users) if "users".in?(params[:include])

      rdvs.includes!(participations: [:user]) if "participations".in?(params[:include])

      rdvs.includes!(motif: [:motif_category]) if "motif".in?(params[:include])
    end

    if params[:id].present?
      rdvs = rdvs.where(id: params[:id])
    end

    if params[:user_id].present?
      rdvs = rdvs.includes(participations: [:user]).where(participations: { user_id: params[:user_id] })
    end

    if params[:agent_id].present?
      rdvs = rdvs.includes(:agents).where(agents: { id: params[:agent_id] })
    end

    if params[:status].present?
      rdvs = rdvs.where(status: params[:status])
    end

    render_collection(rdvs, options: params.permit(include: []))
  end

  # Cet endpoint est utilisé seulement pour la copie des données d'une instance à l'autre, il n'est donc pas documenté.
  def create
    rdv = CreateRdvInNewInstance.new(params:, controller: self, oauth_application: doorkeeper_token&.application).create!

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

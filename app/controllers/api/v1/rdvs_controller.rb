class Api::V1::RdvsController < Api::V1::AgentAuthBaseController
  def index
    rdvs = policy_scope(Rdv, policy_scope_class: Agent::RdvPolicy::Scope).where(params.permit(:organisation_id))

    rdvs = rdvs.starts_after(Time.zone.parse(params[:starts_after])) if params[:starts_after].present?
    rdvs = rdvs.starts_before(Time.zone.parse(params[:starts_before])) if params[:starts_before].present?

    rdvs = rdvs.includes(:organisation, :motif, :lieu, :agents, :users, participations: [:user], motif: [:motif_category])

    if params[:id].present?
      rdvs = rdvs.where(id: params[:id])
    end

    if params[:user_id].present?
      rdvs = rdvs.where(participations: { user_id: params[:user_id] })
    end

    if params[:agent_id].present?
      rdvs = rdvs.where(agents: { id: params[:agent_id] })
    end

    if params[:status].present?
      rdvs = rdvs.where(status: params[:status])
    end

    render_collection(rdvs)
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

  def pundit_user
    current_agent
  end
end

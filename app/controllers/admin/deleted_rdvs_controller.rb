class Admin::DeletedRdvsController < AgentAuthController
  PER_PAGE = 20

  def index
    skip_authorization
    @deleted_rdvs = policy_scope(DeletedRdv, policy_scope_class: Agent::DeletedRdvPolicy::Scope)
      .where(organisation_id: current_organisation.id)
      .ordered_by_deletion
      .includes(:motif, :lieu, :created_by)
      .page(page_number).per(PER_PAGE)

    # Les usagers et agents sont stockés sous forme d'ids : on les charge en une requête chacun pour la page.
    @users_by_id = User.where(id: @deleted_rdvs.flat_map(&:user_ids)).index_by(&:id)
    @agents_by_id = Agent.where(id: @deleted_rdvs.flat_map(&:agent_ids)).index_by(&:id)
  end
end

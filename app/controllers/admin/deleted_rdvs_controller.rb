class Admin::DeletedRdvsController < AgentAuthController
  PER_PAGE = 20

  def index
    authorize(DeletedRdv, :index?, policy_class: Agent::DeletedRdvPolicy)
    @deleted_rdvs = policy_scope(DeletedRdv, policy_scope_class: Agent::DeletedRdvPolicy::Scope)
      .where(organisation_id: current_organisation.id)
      .ordered_by_deletion
      .includes(motif: :organisation, lieu: :organisation)
      .page(page_number).per(PER_PAGE)

    # Les usagers et agents sont stockés sous forme d'ids : on les charge en une requête chacun pour la page.
    @users_by_id = User.where(id: @deleted_rdvs.flat_map(&:user_ids)).includes(:user_profiles).index_by(&:id)
    @agents_by_id = Agent.where(id: @deleted_rdvs.flat_map { _1.agent_ids + [_1.deleted_by_agent_id] }.compact).includes(:organisations).index_by(&:id)
  end
end

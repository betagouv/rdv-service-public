class Admin::Agenda::PlageOuverturesController < Admin::Agenda::BaseController
  def index
    @agent = Agent.find(params[:agent_id])
    @organisation = Organisation.find(params[:organisation_id])

    plage_ouvertures = policy_scope(@agent.plage_ouvertures, policy_scope_class: Agent::PlageOuverturePolicy::Scope)
      .includes(:lieu, :organisation)
    plage_ouvertures = plage_ouvertures.where(id: params[:plages_ids]) if params[:plages_ids].present?

    @plage_ouverture_occurrences = plage_ouvertures.all_occurrences_for(date_range_params)
  end

  private

  def pundit_user
    current_agent
  end
end

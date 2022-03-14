# frozen_string_literal: true

class Admin::Organisations::SetupChecklistsController < AgentAuthController
  before_action :set_organisation

  def show
    authorize(@organisation)
    @lieux = policy_scope(Lieu)
    @motifs = policy_scope(Motif)

    if current_agent.conseiller_numerique?
      render "show_conseiller_numerique"
    else
      @other_agents = policy_scope(Agent)
        .joins(:organisations).where(organisations: { id: current_organisation.id })
        .where.not(id: current_agent)
        .order_by_last_name

      render "show"
    end
  end
end

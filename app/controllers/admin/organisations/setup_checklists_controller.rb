# frozen_string_literal: true

class Admin::Organisations::SetupChecklistsController < AgentAuthController
  before_action :set_organisation

  def show
    authorize(@organisation)
    @lieux = policy_scope(Lieu)
    @other_agents = policy_scope(Agent)
      .joins(:organisations).where(organisations: { id: current_organisation.id })
      .where.not(id: current_agent)
      .order_by_last_name

    @motifs = policy_scope(Motif)
  end
end

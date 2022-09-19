# frozen_string_literal: true

class Admin::Organisations::OnlineBookingsController < AgentAuthController
  before_action :set_organisation
  before_action :check_conseiller_numerique

  def show
    authorize(@organisation)
    all_motifs = policy_scope(Motif).available_motifs_for_organisation_and_agent(current_organisation, current_agent)
    @total_motifs_count = all_motifs.count
    @motifs = all_motifs.reservable_online.includes(:organisation).includes(:service)
  end

  private

  def check_conseiller_numerique
    redirect_to authenticated_agent_root_path unless current_agent.conseiller_numerique?
  end
end

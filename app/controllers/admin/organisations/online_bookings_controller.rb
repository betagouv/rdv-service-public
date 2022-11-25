# frozen_string_literal: true

class Admin::Organisations::OnlineBookingsController < AgentAuthController
  before_action :set_organisation

  helper_method :booking_link

  def show
    authorize(@organisation)

    @motifs = policy_scope(Motif)
      .available_motifs_for_organisation_and_agent(current_organisation, current_agent)
      .active
      .includes(:organisation)
      .includes(:service)
  end

  private

  def booking_link
    public_link_to_org_url(organisation_id: current_organisation.id)
  end
end

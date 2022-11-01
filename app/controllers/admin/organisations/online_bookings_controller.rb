# frozen_string_literal: true

class Admin::Organisations::OnlineBookingsController < AgentAuthController
  before_action :set_organisation
  before_action :check_conseiller_numerique

  helper_method :shareable_booking_link?, :booking_link

  def show
    authorize(@organisation)

    @motifs = policy_scope(Motif)
      .available_motifs_for_organisation_and_agent(current_organisation, current_agent)
      .reservable_online
      .includes(:organisation)
      .includes(:service)

    @plage_ouvertures = policy_scope(PlageOuverture)
      .where(organisation: current_organisation)
      .in_range((Time.zone.now..))
      .reservable_online
      .includes(:lieu, :organisation, :motifs, :agent)
  end

  private

  def check_conseiller_numerique
    redirect_to authenticated_agent_root_path unless current_agent.conseiller_numerique?
  end

  def shareable_booking_link?
    @motifs.any? && @plage_ouvertures.any?
  end

  def booking_link
    public_link_to_org_url(organisation_id: current_organisation.id)
  end
end

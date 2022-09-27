# frozen_string_literal: true

class Admin::Organisations::OnlineBookingsController < AgentAuthController
  before_action :set_organisation
  before_action :check_conseiller_numerique

  helper_method :shareable_booking_link?, :booking_link

  def show
    authorize(@organisation)

    all_motifs = policy_scope(Motif).available_motifs_for_organisation_and_agent(current_organisation, current_agent)
    @total_motifs_count = all_motifs.count
    @motifs = all_motifs.reservable_online.includes(:organisation).includes(:service)

    all_plage_ouvertures = policy_scope(PlageOuverture)
    @total_plage_ouvertures = all_plage_ouvertures.count
    @plage_ouvertures = all_plage_ouvertures.reservable_online.includes(:lieu, :organisation, :motifs, :agent)
  end

  private

  def check_conseiller_numerique
    redirect_to authenticated_agent_root_path unless current_agent.conseiller_numerique?
  end

  def shareable_booking_link?
    @motifs.any? && @plage_ouvertures.any?
  end

  def booking_link
    if current_organisation.external_id.present?
      public_link_to_external_org_url(current_organisation.territory.departement_number, current_organisation.external_id)
    else
      public_link_to_org_url(organisation_id: current_organisation.id)
    end
  end
end

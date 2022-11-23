# frozen_string_literal: true

module Users::CreneauxSearchConcern
  extend ActiveSupport::Concern

  def next_availability
    return available_collective_rdvs.first if motif.collectif?

    NextAvailabilityService.find(motif, @lieu, agents, from: start_booking_delay, to: end_booking_delay)
  end

  def creneaux
    return available_collective_rdvs if motif.collectif?

    reduced_date_range = Lapin::Range.reduce_range_to_delay(motif, date_range) # réduit le range en fonction du délay
    return [] if reduced_date_range.blank?

    SlotBuilder.available_slots(motif, @lieu, reduced_date_range, agents)
  end

  def available_collective_rdvs
    rdvs = Rdv.collectif.future
      .with_remaining_seats
      .not_revoked
      .where(motif_id: motif.id)
      .where(lieu_id: lieu.id)
      .where(starts_at: start_booking_delay..end_booking_delay)
      .order(:starts_at)

    rdvs = rdvs.where.not(id: user.self_and_relatives.flat_map(&:rdv_ids)) if user
    rdvs = rdvs.joins(:agents).where(agents: agents) if agents.any?
    rdvs
  end

  protected

  def agents
    @agents ||= [
      follow_up_rdv_and_online_user? ? @user.agents : nil,
      geo_attributed_agents || nil,
    ].compact.flatten
  end

  def follow_up_rdv_and_online_user?
    @user && motif.follow_up?
  end

  def geo_attributed_agents
    return if @geo_search.nil? || !motif.sectorisation_level_agent?

    @geo_search.attributed_agents_by_organisation[@motif.organisation]
  end
end

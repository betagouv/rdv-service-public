# frozen_string_literal: true

module Users::CreneauxSearchConcern
  extend ActiveSupport::Concern

  def next_availability
    return available_collective_rdvs.first if motif.collectif?

    NextAvailabilityService.find(motif, @lieu, attributed_agents, from: start_booking_delay, to: end_booking_delay)
  end

  def creneaux
    return available_collective_rdvs if motif.collectif?

    reduced_date_range = Lapin::Range.reduce_range_to_delay(motif, date_range) # réduit le range en fonction du délay
    return [] if reduced_date_range.blank?

    SlotBuilder.available_slots(motif, @lieu, reduced_date_range, attributed_agents)
  end

  def available_collective_rdvs
    rdvs = Rdv.collectif.future
      .with_remaining_seats
      .not_revoked
      .where(motif_id: motif.id)
      .where(lieu_id: lieu.id)
      .where(starts_at: start_booking_delay..end_booking_delay)
      .order(:starts_at)

    rdvs = rdvs.joins(:users).where.not(users: { id: user.self_and_relatives.map(&:id) }) if user
    rdvs = rdvs.joins(:agents).where(agents: attributed_agents) if attributed_agents.any?
    rdvs
  end

  protected

  def attributed_agents
    @attributed_agents ||= \
      @agents.presence || (follow_up_agents + geo_attributed_agents)
  end

  def follow_up_agents
    follow_up_rdv_and_online_user? ? @user.agents : []
  end

  def follow_up_rdv_and_online_user?
    @user && motif.follow_up?
  end

  def geo_attributed_agents
    return [] if @geo_search.nil? || !motif.sectorisation_level_agent?

    @geo_search.attributed_agents_by_organisation[@motif.organisation]
  end
end

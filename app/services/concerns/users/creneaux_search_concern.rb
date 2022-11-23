# frozen_string_literal: true

module Users::CreneauxSearchConcern
  extend ActiveSupport::Concern

  def next_availability
    NextAvailabilityService.find(motif, @lieu, agents, from: motif.start_booking_delay, to: motif.end_booking_delay)
  end

  def creneaux
    reduced_date_range = Lapin::Range.reduce_range_to_delay(motif, date_range) # réduit le range en fonction du délay
    return [] if reduced_date_range.blank?

    SlotBuilder.available_slots(motif, @lieu, reduced_date_range, agents)
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

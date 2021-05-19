# frozen_string_literal: true

module Users::CreneauxSearchConcern
  extend ActiveSupport::Concern

  def next_availability
    FindAvailabilityService.perform_with(motif.name, @lieu, date_range.end, **options)
  end

  def creneaux
    CreneauxBuilderService.perform_with(motif.name, @lieu, date_range, **options)
  end

  protected

  def options
    @options ||= {
      agent_ids: agent_ids,
      agent_name: follow_up_rdv_and_online_user?,
      motif_location_type: motif.location_type
    }.select { |_key, value| value } # rejects false and nil but not [] or 0
  end

  def agent_ids
    @agent_ids ||= [
      follow_up_rdv_and_online_user? ? @user.agent_ids : nil,
      geo_attributed_agents ? geo_attributed_agents.pluck(:id) : nil
    ].compact.reduce(:intersection)
  end

  def follow_up_rdv_and_online_user?
    @user && motif.follow_up?
  end

  def geo_attributed_agents
    return if @geo_search.nil? || !motif.sectorisation_level_agent?

    @geo_search.attributed_agents_by_organisation[@lieu.organisation]
  end
end

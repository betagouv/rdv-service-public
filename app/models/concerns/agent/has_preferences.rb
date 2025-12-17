module Agent::HasPreferences
  extend ActiveSupport::Concern

  LATEST_AGENT_SELECTIONS = "latest_agent_selections".freeze

  PREFERENCES = [LATEST_AGENT_SELECTIONS].freeze

  def latest_agent_selections
    preferences[LATEST_AGENT_SELECTIONS] || []
  end

  def append_agent_selection!(agent_ids)
    preferences[LATEST_AGENT_SELECTIONS] ||= []
    preferences[LATEST_AGENT_SELECTIONS].unshift(agent_ids.map(&:to_i))
    preferences[LATEST_AGENT_SELECTIONS] = preferences[LATEST_AGENT_SELECTIONS].uniq { Set.new(_1) }.first(10)
    save_preferences!
  end

  private

  def save_preferences!
    update_columns(preferences:) if preferences_changed? # rubocop:disable Rails/SkipsModelValidations
  end
end

module Agent::FeatureFlags
  extend ActiveSupport::Concern

  CALDAV_SYNC = "caldav_sync".freeze
  NEW_PLANNING = "new_planning".freeze

  AVAILABLE_FEATURES = [CALDAV_SYNC, NEW_PLANNING].freeze

  def feature_enabled?(feature)
    feature_flags && feature_flags[feature] == true
  end

  def toggle_feature!(feature)
    if feature_enabled?(feature)
      disable_feature(feature)
    else
      enable_feature(feature)
    end
    update!(feature_flags: feature_flags)
  end

  private

  def enable_feature(feature)
    return unless AVAILABLE_FEATURES.include?(feature)

    self.feature_flags ||= {}
    self.feature_flags[feature] = true
  end

  def disable_feature(feature)
    self.feature_flags&.delete(feature)
  end
end

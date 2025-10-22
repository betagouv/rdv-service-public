module Agent::FeatureFlags
  extend ActiveSupport::Concern

  CALDAV_SYNC = "caldav_sync".freeze
  NEW_PLANNING = "new_planning".freeze

  AVAILABLE_FEATURES = [CALDAV_SYNC, NEW_PLANNING].freeze

  def feature_enabled?(feature)
    validate_feature_name(feature)
    feature_flags[feature] == true
  end

  def enable_feature!(feature)
    set_feature!(feature, true)
  end

  def disable_feature!(feature)
    set_feature!(feature, false)
  end

  private

  def set_feature!(feature, set_to)
    validate_feature_name(feature)
    feature_flags[feature] = set_to
    update!(feature_flags: feature_flags)
  end

  def validate_feature_name(feature)
    Sentry.capture_message("Invalid feature: #{feature.inspect}") unless feature.in?(AVAILABLE_FEATURES)
  end
end

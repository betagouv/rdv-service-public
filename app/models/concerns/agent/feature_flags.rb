module Agent::FeatureFlags
  extend ActiveSupport::Concern

  CALDAV_SYNC = "caldav_sync".freeze
  NEW_PLANNING = "new_planning".freeze

  AVAILABLE_FEATURES = [CALDAV_SYNC, NEW_PLANNING].freeze

  included do
    before_save :validate_feature_names
  end

  def feature_enabled?(feature)
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
    feature_flags[feature] = set_to
    update!(feature_flags: feature_flags)
  end

  def validate_feature_names
    invalid_features = feature_flags.keys - AVAILABLE_FEATURES
    invalid_features.each { errors.add(:feature_flags, "Invalid feature name: #{_1.inspect}") }
  end
end

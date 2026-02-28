module Agent::FeatureFlags
  extend ActiveSupport::Concern

  NEW_PLANNING = "new_planning".freeze

  AVAILABLE_FEATURES = [NEW_PLANNING].freeze

  def feature_enabled?(feature)
    return true if feature == NEW_PLANNING

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
    raise "Invalid feature name: #{feature.inspect}" unless feature.in?(AVAILABLE_FEATURES)

    feature_flags[feature] = set_to
    update!(feature_flags: feature_flags)
  end
end

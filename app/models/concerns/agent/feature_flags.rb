module Agent::FeatureFlags
  extend ActiveSupport::Concern

  AVAILABLE_FEATURES = %w[new_planning].freeze

  def feature_enabled?(feature)
    feature_flags && feature_flags[feature] == true
  end

  def enable_feature(feature)
    return unless AVAILABLE_FEATURES.include?(feature)

    self.feature_flags ||= {}
    self.feature_flags[feature] = true
  end

  def disable_feature(feature)
    self.feature_flags&.delete(feature)
  end

  def toggle_feature!(feature)
    if feature_enabled?(feature)
      disable_feature(feature)
    else
      enable_feature(feature)
    end
    update!(feature_flags: feature_flags)
  end
end

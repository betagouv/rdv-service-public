module Admin::Api::Agenda
  def self.realtime_refresh?(current_agent)
    if current_agent.feature_enabled?(Agent::FeatureFlags::NEW_PLANNING)
      ENV["REALTIME_AGENDA_FOR_BETA_TESTERS"] == "true"
    else
      ENV["REALTIME_AGENDA_FOR_NON_BETA_TESTERS"] == "true"
    end
  end
end

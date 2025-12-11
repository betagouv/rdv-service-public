module Admin::Planning::SetAgentsConcern
  extend ActiveSupport::Concern

  included do
    before_action do
      @beta_planning_layout = current_agent.feature_enabled?(Agent::FeatureFlags::NEW_PLANNING)
    end
  end

  def set_agents_in_session
    selected_agent_ids = Array(params[:selected_agent_ids]).compact_blank.presence
    if selected_agent_ids
      session[:selected_agent_ids_in_agenda] = selected_agent_ids
      self.my_agent_ids = selected_agent_ids
    end
  end
end

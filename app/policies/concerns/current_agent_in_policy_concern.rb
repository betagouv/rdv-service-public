module CurrentAgentInPolicyConcern
  extend ActiveSupport::Concern

  included do
    alias_method :context, :pundit_user

    def current_agent
      if context.is_a? Agent
        context
      else
        context.agent
      end
    end
  end
end

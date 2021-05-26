# frozen_string_literal: true

module CurrentAgentInPolicyConcern
  extend ActiveSupport::Concern

  included do
    alias_method :context, :pundit_user
    delegate :agent, to: :context, prefix: :current # defines current_agent
  end
end

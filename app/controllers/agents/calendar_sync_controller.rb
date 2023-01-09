# frozen_string_literal: true

class Agents::CalendarSyncController < AgentAuthController
  include Admin::AuthenticatedControllerConcern

  layout "registration"

  def show
    authorize current_agent
  end

  def pundit_user
    AgentContext.new(current_agent)
  end
end

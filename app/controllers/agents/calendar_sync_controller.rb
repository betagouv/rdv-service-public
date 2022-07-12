# frozen_string_literal: true

class Agents::CalendarSyncController < AgentAuthController
  include Admin::AuthenticatedControllerConcern

  layout "registration"

  def show
    @agent = current_agent
    @agent.update!(calendar_uid: new_calendar_uid(current_agent)) if @agent.calendar_uid.nil?
    authorize @agent
  end

  def update
    authorize current_agent
    current_agent.update!(calendar_uid: new_calendar_uid(current_agent))
    redirect_to agents_calendar_sync_path, flash: { notice: "Votre url de calendrier a été mise à jour." }
  end

  def pundit_user
    AgentContext.new(current_agent)
  end

  private

  def new_calendar_uid(agent)
    "#{agent.full_name.parameterize}-#{SecureRandom.uuid}"
  end
end

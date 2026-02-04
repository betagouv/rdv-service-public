class Admin::Api::Agenda::ExternalCalendarEventsController < Admin::Api::BaseController
  def index
    external_calendar_events = ExternalCalendarEvent
      .within_range(time_range_params)
      .where(agent: agents.select(&:caldav_configured?))

    external_calendar_occurrences = []
    external_calendar_events.each do |event|
      event.all_occurrences_within(time_range_params).each do |occurrence|
        external_calendar_occurrences << {
          title: "Indisponibilité provenant d’un agenda externe",
          start: occurrence.starts_at.as_json,
          end: occurrence.ends_at.as_json,
          backgroundColor: AbsencesHelper::CALENDAR_BACKGROUND_COLOR,
          resourceIds: [event.agent_id], # https://fullcalendar.io/docs/resources-and-events
        }
      end
    end

    render json: external_calendar_occurrences
  end

  private

  def agents
    if Array(params[:agent_id]).compact_blank.map(&:to_i) == [current_agent.id]
      [current_agent]
    else
      # La scope de policy pour ExternalCalendarEvent délèguent à Agent::AgentPolicy::Scope.
      # Afin d'améliorer les perfs ici, il est préférable de simplement charger les agents via Agent::AgentPolicy::Scope
      # puis de passer cette liste d'agents en WHERE aux requêtes d'Absence et ExternalCalendarEvent.
      Agent::AgentPolicy::Scope.new(pundit_user, Agent.all).resolve.where(id: params[:agent_id]).load
    end
  end
end

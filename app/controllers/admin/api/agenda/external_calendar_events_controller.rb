class Admin::Api::Agenda::ExternalCalendarEventsController < Admin::Api::BaseController
  def index
    agents_with_caldav_config = agents.select(&:caldav_configured?)
    caldav_configs_by_agent_id = agents_with_caldav_config.to_h { |agent| [agent.id, agent.caldav_config] }

    external_calendar_events = ExternalCalendarEvent
      .within_range(time_range_params)
      .where(agent: agents_with_caldav_config)

    external_calendar_occurrences = []
    external_calendar_events.each do |event|
      caldav_config = caldav_configs_by_agent_id[event.agent_id]
      event.all_occurrences_within(time_range_params).each do |occurrence|
        external_calendar_occurrences << {
          title: external_event_title(caldav_config.caldav_calendar_name),
          start: occurrence.starts_at.as_json,
          end: occurrence.ends_at.as_json,
          color: caldav_config.caldav_calendar_color.presence || AbsencesHelper::CALENDAR_BACKGROUND_COLOR,
          resourceIds: [event.agent_id], # https://fullcalendar.io/docs/resources-and-events
        }
      end
    end

    render json: external_calendar_occurrences
  end

  private

  def external_event_title(calendar_name)
    return "Indisponibilité provenant d’un agenda externe" if calendar_name.blank?

    "Indisponibilité provenant de #{calendar_name}"
  end

  def agents
    if Array(params[:agent_id]).compact_blank.map(&:to_i) == [current_agent.id]
      [current_agent]
    else
      # La scope de policy pour ExternalCalendarEvent délèguent à Agent::AgentPolicy::Scope.
      # Afin d'améliorer les perfs ici, il est préférable de simplement charger les agents via Agent::AgentPolicy::Scope
      # puis de passer cette liste d'agents en WHERE aux requêtes d'Absence et ExternalCalendarEvent.
      Agent::AgentPolicy::Scope.new(pundit_user, Agent.includes(:caldav_config)).resolve.where(id: params[:agent_id]).load
    end
  end
end

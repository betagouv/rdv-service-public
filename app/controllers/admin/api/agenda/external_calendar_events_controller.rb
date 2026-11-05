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
        all_day = all_day?(occurrence)
        external_calendar_occurrences << {
          title: external_event_title(caldav_config.caldav_calendar_name),
          start: all_day ? occurrence.starts_at.to_date.as_json : occurrence.starts_at.as_json,
          end: all_day ? occurrence.ends_at.to_date.as_json : occurrence.ends_at.as_json,
          allDay: all_day,
          color: caldav_config.caldav_calendar_color.presence || AbsencesHelper::CALENDAR_BACKGROUND_COLOR,
          resourceIds: [event.agent_id], # https://fullcalendar.io/docs/resources-and-events
        }
      end
    end

    render json: external_calendar_occurrences
  end

  private

  # Les événements "toute la journée" (DTSTART;VALUE=DATE en iCal) sont stockés de minuit à minuit
  def all_day?(occurrence)
    occurrence.starts_at == occurrence.starts_at.beginning_of_day &&
      occurrence.ends_at == occurrence.ends_at.beginning_of_day
  end

  def external_event_title(calendar_name)
    return "Indisponibilité provenant d’un agenda externe" if calendar_name.blank?

    "#{calendar_name} - Indisponibilité synchronisée"
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

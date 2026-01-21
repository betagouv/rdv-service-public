class Admin::Api::Agenda::AbsencesController < Admin::Api::BaseController
  def index
    @organisation = Organisation.find(params[:organisation_id])

    # Les scopes de policy pour les Absence et les ExternalCalendarEvent délèguent à Agent::AgentPolicy::Scope.
    # Afin d'améliorer les perfs ici, il est préférable de simplement charger les agents via Agent::AgentPolicy::Scope
    # puis de passer cette liste d'agents en WHERE aux requêtes d'Absence et ExternalCalendarEvent.
    agents = Agent::AgentPolicy::Scope.new(pundit_user, Agent.all).resolve.where(id: params[:agent_id]).load

    @absence_occurrences = Absence.where(agent: agents).all_occurrences_for(date_range_params)
    @external_calendar_occurrences = external_event_occurrences(agents)
  end

  private

  def external_event_occurrences(agents)
    external_calendar_events = ExternalCalendarEvent
      .within_range(time_range_params)
      .where(agent: agents.select(&:caldav_configured?))

    occurrences_hashes = []
    external_calendar_events.each do |event|
      event.all_occurrences_within(time_range_params).each do |occurrence|
        occurrences_hashes << {
          title: "Indisponibilité provenant d’un agenda externe",
          start: occurrence.starts_at.as_json,
          end: occurrence.ends_at.as_json,
          backgroundColor: AbsencesHelper::CALENDAR_BACKGROUND_COLOR,
          resourceIds: [event.agent_id], # https://fullcalendar.io/docs/resources-and-events
        }
      end
    end

    occurrences_hashes
  end
end

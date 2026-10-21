class Caldav::Event
  def initialize(calendav_event)
    @calendav_event = calendav_event
  end

  delegate :url, :calendar_data, to: :@calendav_event
  delegate :dtstart, :dtend, :transp, to: :inner_event

  def to_external_calendar_event_hash(agent_id)
    {
      agent_id:,
      url:,
      starts_at: dtstart,
      ends_at: dtend,
      raw_ical: recurring? ? Ical::Scrubber.new(calendar_data).scrubbed : nil,
      etag: @calendav_event.etag,
    }
  end

  # Voici comment est définit l'attribut TRANSP dans la spec iCal :
  # > TRANSP : This property defines whether an event is transparent or not to busy time searches.
  def consider_busy?
    if recurring?
      # Les événements récurrents peuvent être initialement TRANSPARENT
      # mais avoir des occurrences exceptionnellement OPAQUE
      @calendav_event.calendar_data.include?("TRANSP:OPAQUE")
    else
      transp != "TRANSPARENT"
    end
  end

  def recurring?
    inner_event.rrule&.first&.valid?
  end

  def inner_event
    # inner_event est coûteux à obtenir dans Calendav (l'iCal est re-parsé à chaque appel, y compris via dtstart,
    # dtend et transp) donc on memoize et on lit toutes les propriétés depuis cet objet.
    @inner_event ||= @calendav_event.send(:inner_event)
  end

  def not_a_todo?
    # Dans les deux cas suivants, on rejette les changements qui ne sont pas des événements
    # (c’est notamment le cas des VTODO qui peuvent être mélangées avec les VEVENT dans certains serveurs Caldav)
    # On met à jour les événements modifiés qui sont « OPAQUE » (considérés comme occupés)
    #
    # Les événements sans DTEND (anniversaires, rappels...) ne sont pas bloquants et sont ignorés
    dtend.present?
  end

  def blocks_calendar?
    not_a_todo? && consider_busy?
  end
end

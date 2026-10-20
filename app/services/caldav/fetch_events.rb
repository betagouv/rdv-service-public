class Caldav::FetchEvents
  def initialize(agent, sync_logger)
    @agent = agent
    @sync_logger = sync_logger
  end

  def fetch_changes
    if caldav_config.caldav_sync_token
      sync_logger.log("Sync token found: loading only new events")
      @updated_events, @deleted_event_urls, @new_sync_token = changes_since_last_sync
      return
    end

    calendar = caldav_client.calendars.find(caldav_config.caldav_agenda_url, sync: true)

    if calendar.sync_token.present?
      sync_logger.log("First sync: loading all events (paginated)")
      @updated_events = initial_fetch
      @deleted_event_urls = []
      @new_sync_token = calendar.sync_token
      return
    end

    if calendar.ctag.present?
      @updated_events, @deleted_event_urls = fetch_by_ctag(calendar)
      @new_ctag = calendar.ctag
      return
    end

    raise "pas de sync token ni de ctag sur le calendrier distant"
  end

  def updated_events
    (@updated_events || []).select(&:blocks_calendar?)
  end

  def deleted_event_urls
    @deleted_event_urls || []
  end

  def any_changes?
    updated_events.any? || deleted_event_urls.any?
  end

  attr_reader :new_sync_token, :new_ctag

  private

  attr_reader :sync_logger

  # Certains serveurs (Zimbra notamment) ne supportent pas le report sync-collection (RFC 6578)
  # et ne renvoient pas de sync token. On s'appuie alors sur le ctag du calendrier, qui change
  # à chaque modification d'un de ses événements.
  def fetch_by_ctag(calendar)
    if calendar.ctag == caldav_config.caldav_ctag
      sync_logger.log("No sync token support: ctag unchanged, nothing to load")
    elsif caldav_config.caldav_ctag.present?
      sync_logger.log("No sync token support: ctag changed, loading only new or updated events")
      updated_events, deleted_event_urls = changed_events_by_etag
    else
      sync_logger.log("No sync token support: ctag changed, loading all events")
      updated_events = initial_fetch
      deleted_event_urls = []
    end
    [updated_events, deleted_event_urls]
  end

  def changes_since_last_sync
    collection = caldav_client.calendars.sync(caldav_config.caldav_agenda_url, caldav_config.caldav_sync_token)
    new_sync_token = collection.sync_token

    updated_events, deleted_events = collection.changes.map { Caldav::Event.new(_1) }.partition do |event|
      event.calendar_data && # Le serveur Caldav de la Suite Numérique signale une suppression à travers un calendar_data vide.
        event.inner_event &&
        event.blocks_calendar? # On supprime les événements modifiés qui sont « TRANSPARENT » (considérés comme libres)
    end

    deleted_event_urls = deleted_events.map(&:url)

    # D'autres serveurs Caldav peuvent utiliser le tableau `deletions` pour signaler une suppression
    deleted_event_urls += collection.deletions

    [updated_events, deleted_event_urls, new_sync_token]
  end

  def initial_fetch
    caldav_client.events.list(caldav_config.caldav_agenda_url).map { Caldav::Event.new(_1) } # Cette méthode ne récupère que les événements et rejette bien les VTODO
  end

  # On compare les etags du serveur avec ceux stockés localement, pour ne télécharger que les événements
  # nouveaux ou modifiés, et ne supprimer que ceux qui ont disparu du serveur.
  def changed_events_by_etag
    remote_etags = caldav_etag_client.etags(caldav_config.caldav_agenda_url)
    local_etags = ExternalCalendarEvent.where(agent: @agent).pluck(:url, :etag).to_h

    # Les événements provenant de nos RDV sont ignorés : inutile de les télécharger
    urls_of_rdvs = AgentsRdv.where(caldav_url: remote_etags.keys).pluck(:caldav_url)
    changed_urls = remote_etags.reject { |url, etag| local_etags[url] == etag }.keys - urls_of_rdvs

    # On rejette les ressources qui ne sont pas des événements (VTODO notamment)
    changed_events = caldav_etag_client.events(caldav_config.caldav_agenda_url, changed_urls.sort)
      .select { _1.calendar_data && _1.send(:inner_event) }
      .map { Caldav::Event.new(_1) }
    updated_events, not_busy_events = changed_events.partition(&:consider_busy?)

    deleted_event_urls = (local_etags.keys - remote_etags.keys) + (not_busy_events.map(&:url) & local_etags.keys)

    [updated_events, deleted_event_urls]
  end

  def caldav_config
    @agent.caldav_config
  end

  def caldav_client
    caldav_config.caldav_client
  end

  def caldav_etag_client
    caldav_config.caldav_etag_client
  end
end

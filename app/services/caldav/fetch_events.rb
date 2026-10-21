class Caldav::FetchEvents
  BATCH_SIZE = 200

  def initialize(agent, sync_logger)
    @agent = agent
    @sync_logger = sync_logger
  end

  def fetch_changes
    if caldav_config.caldav_sync_token
      sync_logger.log("Sync token found: loading only new events")
      updated_events, @deleted_event_urls, @new_sync_token = changes_since_last_sync
      @event_batches = updated_events.each_slice(BATCH_SIZE)
      return
    end

    calendar = caldav_client.calendars.find(caldav_config.caldav_agenda_url, sync: true)

    if calendar.sync_token.present?
      sync_logger.log("First sync: loading all events (paginated)")
      @event_batches = initial_fetch
      @deleted_event_urls = []
      @new_sync_token = calendar.sync_token
      return
    end

    if calendar.ctag.present?
      @event_batches = fetch_by_ctag(calendar)
      @new_ctag = calendar.ctag
      return
    end

    raise "pas de sync token ni de ctag sur le calendrier distant"
  end

  # Les événements sont traités par lots pour ne pas garder tous les iCal parsés en mémoire.
  # À n'appeler qu'une fois : les lots sont produits à la volée, et deleted_event_urls n'est
  # complet qu'une fois tous les lots consommés.
  def each_updated_batch
    @updated_count = 0
    (@event_batches || []).each do |events|
      updated_events = events.select(&:blocks_calendar?)
      @updated_count += updated_events.size
      yield updated_events
    end
  end

  def deleted_event_urls
    @deleted_event_urls || []
  end

  def any_changes?
    @updated_count.to_i.positive? || deleted_event_urls.any?
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
      @deleted_event_urls = []
      []
    elsif caldav_config.caldav_ctag.present?
      sync_logger.log("No sync token support: ctag changed, loading only new or updated events")
      changed_events_by_etag
    else
      sync_logger.log("No sync token support: ctag changed, loading all events")
      @deleted_event_urls = []
      initial_fetch
    end
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
    # Cette méthode ne récupère que les événements et rejette bien les VTODO
    calendav_events = caldav_client.events.list(caldav_config.caldav_agenda_url)

    # Calendav garde l'iCal parsé dans chaque événement, donc tant que ce tableau les référence, rien de ce
    # qui a été parsé ne peut être libéré. On vide donc chaque case au fur et à mesure (et on évite shift/slice!
    # qui partagent le tampon d'origine et le gardent en mémoire en entier).
    Enumerator.new do |batches|
      (0...calendav_events.size).step(BATCH_SIZE) do |start|
        indexes = start...[start + BATCH_SIZE, calendav_events.size].min
        batches << indexes.map { |i| Caldav::Event.new(calendav_events[i]).tap { calendav_events[i] = nil } }
      end
    end
  end

  # On compare les etags du serveur avec ceux stockés localement, pour ne télécharger que les événements
  # nouveaux ou modifiés, et ne supprimer que ceux qui ont disparu du serveur.
  def changed_events_by_etag
    remote_etags = caldav_etag_client.etags(caldav_config.caldav_agenda_url)
    local_etags = ExternalCalendarEvent.where(agent: @agent).pluck(:url, :etag).to_h

    # Les événements provenant de nos RDV sont ignorés : inutile de les télécharger
    urls_of_rdvs = AgentsRdv.where(caldav_url: remote_etags.keys).pluck(:caldav_url)
    changed_urls = remote_etags.reject { |url, etag| local_etags[url] == etag }.keys - urls_of_rdvs

    # Les événements à supprimer ne sont connus en entier qu'une fois tous les lots consommés
    @deleted_event_urls = local_etags.keys - remote_etags.keys

    caldav_etag_client.events_in_batches(caldav_config.caldav_agenda_url, changed_urls.sort).map do |calendav_events|
      # On rejette les ressources qui ne sont pas des événements (VTODO notamment)
      events = calendav_events.map { Caldav::Event.new(_1) }.select { _1.calendar_data && _1.inner_event }
      busy_events, not_busy_events = events.partition(&:consider_busy?)
      @deleted_event_urls += not_busy_events.map(&:url) & local_etags.keys
      busy_events
    end
  end

  def caldav_config
    @agent.caldav_config
  end

  def caldav_client
    caldav_config.caldav_client
  end

  def caldav_etag_client
    @caldav_etag_client ||= Caldav::EtagClient.new(caldav_config.caldav_credentials)
  end
end

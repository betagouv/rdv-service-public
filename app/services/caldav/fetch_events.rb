class Caldav::FetchEvents
  def initialize(agent, sync_logger)
    @agent = agent
    @sync_logger = sync_logger
  end

  attr_reader :sync_logger

  def fetch_changes
    if caldav_config.caldav_sync_token
      sync_logger.log("Sync token found: loading only new events")
      return changes_since_last_sync
    end

    calendar = caldav_client.calendars.find(caldav_config.caldav_agenda_url, sync: true)

    if calendar.sync_token.present?
      sync_logger.log("First sync: loading all events (paginated)")
      updated_events = initial_fetch_for_sync_token
      new_sync_token = calendar.sync_token
    else
      # Certains serveurs (Zimbra notamment) ne supportent pas le report sync-collection (RFC 6578)
      # et ne renvoient pas de sync token. On s'appuie alors sur le ctag du calendrier, qui change
      # à chaque modification d'un de ses événements.
      if calendar.ctag.present? && calendar.ctag == caldav_config.caldav_ctag
        sync_logger.log("No sync token support: ctag unchanged, nothing to load")
      elsif calendar.ctag.present? && caldav_config.caldav_ctag.present?
        sync_logger.log("No sync token support: ctag changed, loading only new or updated events")
        updated_events, deleted_event_urls = changed_events_by_etag
      elsif calendar.ctag.present?
        sync_logger.log("No sync token support: ctag changed, loading all events")
        updated_events, deleted_event_urls = all_events_with_deletions
      else
        raise "pas de ctag sur le calendrier distan"
      end
      new_ctag = calendar.ctag
    end

    updated_events = (updated_events || []).select { consider_busy?(_1) }

    [updated_events, deleted_event_urls || [], new_sync_token, new_ctag]
  end

  private

  def changes_since_last_sync
    collection = caldav_client.calendars.sync(caldav_config.caldav_agenda_url, caldav_config.caldav_sync_token)
    new_sync_token = collection.sync_token

    # Dans les deux cas suivants, on rejette les changements qui ne sont pas des événements
    # (c’est notamment le cas des VTODO qui peuvent être mélangées avec les VEVENT dans certains serveurs Caldav)
    # On met à jour les événements modifiés qui sont « OPAQUE » (considérés comme occupés)
    updated_events = collection.changes.select { _1.calendar_data && _1.send(:inner_event) }.select { |event| consider_busy?(event) }
    # On supprime les événements modifiés qui sont « TRANSPARENT » (considérés comme libres)
    deleted_event_urls = collection.changes.select { _1.calendar_data && _1.send(:inner_event) }.reject { |event| consider_busy?(event) }.map(&:url)

    # Le serveur Caldav de la Suite Numérique signale une suppression à travers un calendar_data vide.
    deleted_event_urls += collection.changes.reject(&:calendar_data).map(&:url)

    # D'autres serveurs Caldav peuvent utiliser le tableau `deletions` pour signaler une suppression
    deleted_event_urls += collection.deletions

    updated_events = updated_events.select { consider_busy?(_1) }

    [updated_events, deleted_event_urls, new_sync_token]
  end

  def initial_fetch_for_sync_token
    caldav_client.events.list(caldav_config.caldav_agenda_url) # Cette méthode ne récupère que les événements et rejette bien les VTODO
  end

  def all_events_with_deletions
    updated_events = caldav_client.events.list(caldav_config.caldav_agenda_url)

    # Sans sync token, le serveur ne nous signale pas les suppressions : on supprime donc les événements locaux
    # qui ne sont plus présents sur le serveur, ou qui n'y sont plus considérés comme occupés (TRANSPARENT).
    busy_urls = updated_events.select { consider_busy?(_1) }.map(&:url)
    deleted_event_urls = ExternalCalendarEvent.where(agent: @agent).where.not(url: busy_urls).pluck(:url)

    [updated_events, deleted_event_urls]
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
    updated_events, not_busy_events = changed_events.partition { consider_busy?(_1) }

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

  # Voici comment est définit l'attribut TRANSP dans la spec iCal :
  # > TRANSP : This property defines whether an event is transparent or not to busy time searches.
  def consider_busy?(event)
    if recurring?(event)
      # Les événements récurrents peuvent être initialement TRANSPARENT
      # mais avoir des occurrences exceptionnellement OPAQUE
      event.calendar_data.include?("TRANSP:OPAQUE")
    else
      event.transp != "TRANSPARENT"
    end
  end

  def recurring?(event)
    event.send(:inner_event).rrule&.first&.valid?
  end
end

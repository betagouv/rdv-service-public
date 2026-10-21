module CaldavUtils
  # Privilèges WebDAV (RFC 3744) qui donnent un accès complet en écriture.
  # "write" est un privilège agrégé de write-properties, write-content, bind et unbind,
  # et "all" inclut tous les privilèges.
  FULL_WRITE_PRIVILEGES = %w[all write].freeze
  WRITE_COMPONENT_PRIVILEGES = %w[write-properties write-content bind unbind].freeze

  # Un calendrier est considéré comme entièrement modifiable uniquement si le serveur
  # nous a communiqué le privilège "all" ou "write", ou bien les quatre privilèges
  # qui composent "write" (certains serveurs ne listent pas le privilège agrégé).
  # Un accès partiel (ex : seulement "bind" pour ajouter des événements) ne suffit pas.
  # Si le serveur n’expose pas current-user-privilege-set, on ne peut pas confirmer
  # l’accès en écriture : on renvoie false.
  #
  # @param [Calendav::Calendar] calendar
  def self.fully_writable?(calendar)
    privileges = calendar.current_user_privilege_set
    return false if privileges.blank?
    return true if privileges.intersect?(FULL_WRITE_PRIVILEGES)

    privileges.to_set.superset?(WRITE_COMPONENT_PRIVILEGES.to_set)
  end

  def self.generate_test_event_uid
    "rdvsp-connection-test-#{SecureRandom.uuid}"
  end

  def self.generate_test_event(event_uid)
    Icalendar::Calendar.new.tap do |cal|
      cal.prodid = "RDV Service Public"
      cal.event do |event|
        event.uid = "rdvsp-connection-test-#{event_uid}"
        event.dtstart = Icalendar::Values::DateTime.new(Time.now.change(hour: 0).utc)
        event.dtend = Icalendar::Values::DateTime.new(Time.now.change(hour: 1).utc)
        event.summary = "Test de connexion RDV Service Public"
      end
    end
  end
end

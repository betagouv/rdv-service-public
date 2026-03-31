class Agents::CaldavSyncController < AgentAuthController
  layout "application_agent_config"

  def show
    skip_authorization
  end

  def update
    skip_authorization
    current_agent.assign_attributes(
      caldav_agenda_url: params[:caldav_agenda_url],
      caldav_username: params[:caldav_username],
      caldav_password: params[:caldav_password]
    )

    error = caldav_config_error
    if error.nil?
      flash[:success] = "La synchronisation avec votre agenda CalDAV #{current_agent.caldav_username} est activée."
      current_agent.save!
      Caldav::MassExportEventToCaldavJob.perform_later(current_agent)
    else
      flash[:alert] = error
    end

    redirect_to agents_calendar_sync_caldav_sync_path
  end

  def destroy
    skip_authorization
    current_agent.update!(caldav_disconnect_started_at: Time.current)
    Caldav::MassDestroyEventsAndAbsencesJob.perform_later(current_agent)
    redirect_to agents_calendar_sync_caldav_sync_path
  end

  private

  # Vérifie la configuration CalDAV en 3 étapes : authentification, lecture, écriture.
  # Retourne nil si tout est OK, ou un message d’erreur décrivant l’étape qui a échoué.
  def caldav_config_error
    client = current_agent.caldav_client
    agenda_url = params[:caldav_agenda_url]

    begin
      client.principal_url
    rescue StandardError
      return "L’authentification a échoué. Veuillez vérifier votre identifiant et votre mot de passe."
    end

    begin
      client.calendars.find(agenda_url)
    rescue StandardError
      return "L’accès en lecture au calendrier a échoué. Veuillez vérifier l’URL de l’agenda."
    end

    begin
      identifier = "rdvsp-connection-test-#{SecureRandom.uuid}.ics"
      test_event = client.events.create(agenda_url, identifier, test_event_ics)
      client.events.delete(test_event.url) # On nettoie l’événement de test qu’on vient de créer
    rescue StandardError
      return "L’accès en écriture au calendrier a échoué. Veuillez vérifier vos droits d’accès à l’agenda."
    end

    nil
  end

  def test_event_ics
    cal = Icalendar::Calendar.new
    cal.prodid = "RDV Service Public"
    cal.event do |event|
      event.uid = "rdvsp-connection-test-#{SecureRandom.uuid}"
      event.dtstart = Icalendar::Values::DateTime.new(Time.now.change(hour: 0, min: 0, sec: 0).utc)
      event.dtend = Icalendar::Values::DateTime.new(Time.now.change(hour: 1, min: 0, sec: 0).utc)
      event.summary = "Test de connexion RDV Service Public"
    end
    cal.to_ical
  end

  def pundit_user
    AgentContext.new(current_agent)
  end
end

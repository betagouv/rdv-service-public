# Calendav re-parse l'iCal complet à chaque appel à `dtstart`, `dtend`, `transp`… : `inner_event` ne mémoïse rien
# (`@inner_event = …` au lieu de `||=`) et `inner_calendar` non plus. Sur un gros calendrier, cela représente une
# dizaine de parses par événement, avec beaucoup de mémoire allouée et un temps de synchro très allongé.
# On mémoïse donc au plus bas, pour que tous les appels d'un même événement partagent le même objet parsé.
# TODO: supprimer quand la memoization est ajoutée à la gem : https://github.com/pat/calendav/pull/17
module CalendavInnerEventMemoization
  private

  def inner_calendar
    return @inner_calendar if defined?(@inner_calendar)

    @inner_calendar = super
  end

  def inner_event
    return @inner_event if defined?(@inner_event)

    @inner_event = super
  end
end

Calendav::Event.prepend(CalendavInnerEventMemoization)

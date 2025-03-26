import frLocale from '@fullcalendar/core/locales/fr';

const defaultFullCalendarConfig = () => ({
  locale: frLocale,
  allDaySlot: false,
  height: "auto",
  selectable: true,
  nowIndicator: true,
  businessHours: {
    // days of week. an array of zero-based day of week integers (0=Sunday)
    daysOfWeek: [1, 2, 3, 4, 5, 6, 0],
      startTime: '07:00',
      endTime: '19:00',
  },
  slotMinTime: '07:00:00',
  slotMaxTime: '20:00:00',
  eventMouseLeave: (info) => $(info.el).tooltip('hide'), // extra security
    timeZone: "Europe/Paris" // This is a hack to make sure that the events will be shown at the proper time in the calendar.
  // If this is removed, there is a bug that causes the events in the calendar to be show at the wrong
  // time for agents that are not in the Paris timezone.
  // The proper fix for this would be to make sure we store all rdvs with the right timezone, but that's a much bigger project.
  // The timezone is forced to paris on the server side, so if we make sure that we also force it to the same timezone here,
  // we always have a consistent result.
  // We're always assuming that people are interested in their local time.
  //
  // There is one case for which this fix would fail: if the local time of the user and the agent is not the same (for example the agent is
  // in the métropole and the user is at la réunion), they will not see the same time
  // for the rdv. This seems unlikely for now.
})

function eventRenderer(selectedEventId) {
  // On renvoie une fonction qui aura le bon selectedEventId
  return (info) => {
    let $el = $(info.el);
    let extendedProps = info.event.extendedProps;

    if (extendedProps.past == true) {
      $el.addClass("fc-event-past");
    };
    if (extendedProps.duration <= 30) {
      $el.addClass("fc-event-small");
    };
    if (extendedProps.unauthorizedRdvExplanation) {
      $el.addClass("fc-unauthorized-rdv");
    };

    if (selectedEventId && info.event.id == selectedEventId)
      $el.addClass("selected");

    $el.addClass("fc-event-" + extendedProps.status);

    if (extendedProps.userInWaitingRoom == true) {
      $el.addClass("fc-event-waiting");
    }

    if (extendedProps.jour_feries == true) {
      return
    }

    let title = ``;
    const start = Intl.DateTimeFormat("fr", { timeZone: 'UTC', hour: 'numeric', minute: 'numeric' }).format(info.event.start);
    const end = Intl.DateTimeFormat("fr", { timeZone: 'UTC', hour: 'numeric', minute: 'numeric' }).format(info.event.end);

    if (info.isStart && info.isEnd) {
      title += `${start} - ${end}`;
    } else if (info.isStart) {
      title += `À partir de ${start}`;
    } else if (info.isEnd) {
      title += `Jusqu'à ${end}`;
    } else {
      title += `Toute la journée`;
    }

    if (info.event.display == 'background') {
      if (extendedProps.organisationName) {
        title += `<br>${extendedProps.organisationName}`;
      }
      title += `<br><strong>${info.event.title}</strong>`;
      if (extendedProps.lieu) {
        title += `<br> <small>Lieu : ${extendedProps.lieu}</small>`;
      }
    } else {
      if (extendedProps.duration) {
        title += ` <small>(${extendedProps.duration} min)</small>`;
        title += ` <br>${extendedProps.motif}`;
      }

      title += `<br><strong>${info.event.title}</strong>`;

      if (extendedProps.organisationName) {
        title += `<br>${extendedProps.organisationName}`;
      }
      if (extendedProps.lieu) {
        title += `<br><strong>Lieu:</strong> ${extendedProps.lieu}`;
      }
      if (extendedProps.readableStatus) {
        title += `<br><strong>Statut:</strong> ${extendedProps.readableStatus}`;
      }
      if (extendedProps.unauthorizedRdvExplanation) {
        title += `<br>${extendedProps.unauthorizedRdvExplanation}`;
      }
    }

    $el.attr("title", title);
    $el.attr("data-toggle", "tooltip");
    $el.attr("data-html", "true");
    $el.tooltip()
  }
}

export { defaultFullCalendarConfig, eventRenderer }

import { Calendar } from '@fullcalendar/core';
import timeGridPlugin from '@fullcalendar/timegrid';
import frLocale from '@fullcalendar/core/locales/fr';
import interactionPlugin from '@fullcalendar/interaction';

class RdvPlanCalendar {

  constructor() {
    this.calendarEl = document.getElementById('rdvPlanCalendar');
    if (this.calendarEl == null || this.calendarEl.innerHTML !== "")
      return

    this.data = this.calendarEl.dataset
    this.fullCalendarInstance = this.initFullCalendar(this.calendarEl)
    this.fullCalendarInstance.render();
  }

  initFullCalendar = () => {
    var hiddenDays = []
    if (this.data.displaySaturdays !== "true") {
      hiddenDays.push(6);
    }
    if (this.data.displaySundays !== "true") {
      hiddenDays.push(0);
    }

    const options = {
      plugins: [timeGridPlugin, interactionPlugin],
      locale: frLocale,
      eventSources: JSON.parse(this.data.eventSourcesJson),
      defaultDate: JSON.parse(this.data.defaultDateJson),
      allDaySlot: false,
      nowIndicator: true,
      defaultView: this.data.singleDay === "true" ? 'timeGridDay' : 'timeGridWeek',
      hiddenDays: hiddenDays,
      height: "auto",
      selectable: true,
      select: this.selectEvent,
      businessHours: {
        // days of week. an array of zero-based day of week integers (0=Sunday)
        daysOfWeek: [1, 2, 3, 4, 5, 6, 0],
        startTime: '07:00',
        endTime: '19:00',
      },
      minTime: this.data.minTime || '07:00:00',
      maxTime: this.data.maxTime || '20:00:00',
      eventRender: this.eventRender,
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
      // see the same time for the rdv. This seems unlikely for now.
    }

    if (this.data.singleDay === "true") {
      options.header = { left:  '', center: '', right:  '' };
    } else {
      options.header = { left:  '', center: '', right:  'prev,next' };
    }

    return new Calendar(this.calendarEl, options);
  }

  selectEvent = (info) => {
    const urlSearchParams = new URLSearchParams({
      user_id: this.data.userId,
      starts_at: info.startStr,
    });
    const field = document.getElementById('rdvPlanCalendarField')
    field.value = info.startStr
    const form = document.getElementById('rdvPlanCalendarForm')
    form.submit()
  }

  // TODO: extraire cette fonction pour la partager avec l'autre calendrier
  eventRender = (info) => {
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

    if (this.data.selectedEventId && info.event.id == this.data.selectedEventId)
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

    if (info.event.rendering == 'background') {
      $el.append("<div class=\"fc-title\" style=\"color: white; padding: 2px 4px; font-size: 12px; font-weight: bold;\">" + info.event.title + "</div>");

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

document.addEventListener('turbolinks:load', function () {
  new RdvPlanCalendar()
});

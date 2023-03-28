import { Calendar } from '@fullcalendar/core';
import dayGridPlugin from '@fullcalendar/daygrid';
import timeGridPlugin from '@fullcalendar/timegrid';
import listPlugin from '@fullcalendar/list';
import frLocale from '@fullcalendar/core/locales/fr';
import interactionPlugin from '@fullcalendar/interaction';

import Bowser from "bowser";
const browser = Bowser.getParser(window.navigator.userAgent);

class CalendarRdvSolidarites {

  constructor() {
    this.calendarEl = document.getElementById('calendar');
    if (this.calendarEl == null || this.calendarEl.innerHTML !== "")
      return

    this.data = this.calendarEl.dataset
    this.fullCalendarInstance = this.initFullCalendar(this.calendarEl)
    this.fullCalendarInstance.render();

    document.addEventListener('turbolinks:before-cache', this.clearRefetchInterval);
    document.addEventListener('turbolinks:before-render', this.clearRefetchInterval);
    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'visible') {
        this.setRefetchInterval();
      } else if (this.refreshCalendarInterval) {
        this.clearRefetchInterval()
      }
    })
    document.addEventListener("turbolinks:before-cache", () => {
      // force calendar reload on turbolinks re-visit, otherwise event listeners
      // are not attached
      this.calendarEl.innerHTML = ""
      this.currentViewType = null
      this.currentTodayVisible = null
      // fixes hanging tooltip on back
      $(".tooltip").removeClass("show")
    })
    this.setRefetchInterval()
  }

  setRefetchInterval = () => {
    if (this.refreshCalendarInterval) return
    this.refreshCalendarInterval = setInterval(() => this.fullCalendarInstance.refetchEvents(), 60000)
  }

  clearRefetchInterval = () => {
    if (!this.refreshCalendarInterval) return
    clearTimeout(this.refreshCalendarInterval)
    this.refreshCalendarInterval = null
  }

  initFullCalendar = () => {
    return new Calendar(this.calendarEl, {
      plugins: [dayGridPlugin, timeGridPlugin, listPlugin, interactionPlugin],
      locale: frLocale,
      eventSources: JSON.parse(this.data.eventSourcesJson),
      eventSourceFailure: this.handleAjaxError,
      defaultDate: this.getDefaultDate(),
      defaultView: this.getDefaultView(),
      viewSkeletonRender: function (info) {
        localStorage.setItem("calendarDefaultView", info.view.type);
      },
      hiddenDays: this.data.displaySaturdays === "true" ? [0] : [6, 0],
      height: "auto",
      selectable: true,
      select: this.selectEvent,
      header: {
        center: 'dayGridMonth,timeGridWeek,timeGridOneDay,listWeek'
      },
      views: {
        timeGridOneDay: {
          type: 'timeGrid',
          duration: { days: 1 },
          buttonText: 'Journée'
        }
      },
      businessHours: {
        // days of week. an array of zero-based day of week integers (0=Sunday)
        daysOfWeek: [1, 2, 3, 4, 5, 6],
        startTime: '07:00',
        endTime: '19:00',
      },
      minTime: '07:00:00',
      maxTime: '20:00:00',
      datesRender: this.datesRender,
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
    });
  }

  getDefaultView = () => {
    let defaultView = "timeGridOneDay";
    if (!browser.is("mobile")) {
      let viewFromLocalStorage = localStorage.getItem("calendarDefaultView");

      defaultView = ['dayGridMonth', 'timeGridWeek', 'timeGridOneDay'].includes(viewFromLocalStorage) ? viewFromLocalStorage : "timeGridWeek";
    }
    return defaultView;
  }

  getDefaultDate = () => {
    return JSON.parse(this.data.defaultDateJson || sessionStorage.getItem('calendarStartDate'))
  }

  selectEvent = (info) => {
    const urlSearchParams = new URLSearchParams({
      starts_at: info.startStr,
      "agent_ids[]": this.data.agentId,
    });
    window.location = `/admin/organisations/${this.data.organisationId}/rdv_wizard_step/new?${urlSearchParams.toString()}`;;
  }

  datesRender = (info) => {
    if (
      this.currentTodayVisible && !this.isTodayVisible(info.view) &&
      this.currentViewType &&
      (
        (this.currentViewType == 'dayGridMonth' && info.view.type == 'timeGridWeek') ||
        (['dayGridMonth', 'timeGridWeek'].indexOf(this.currentViewType) >= 0 && info.view.type == 'timeGridOneDay')
      )
    ) {
      this.fullCalendarInstance.gotoDate(new Date())
      return false // unfortunately this does not cancel the current rendering but it's fast
    }
    this.currentTodayVisible = this.isTodayVisible(info.view);
    this.currentViewType = info.view.type;

    sessionStorage.setItem("calendarStartDate", JSON.stringify(info.view.currentStart))
    const printLinkElt = document.querySelector(".js-link-print-rdvs")

    if (printLinkElt) {
      printLinkElt.classList.toggle("d-none", info.view.type != "timeGridOneDay")
      if (info.view.type != "timeGridOneDay") return

      const url = new URL(printLinkElt.href)
      printLinkElt.querySelector(".js-date").innerHTML = Intl.DateTimeFormat("fr", { day: "numeric", month: "numeric", year: "numeric" }).format(info.view.currentStart)
      const currentStart = info.view.currentStart.toISOString().split('T')[0]
      url.searchParams.set("start", currentStart)
      url.searchParams.set("end", currentStart)


      printLinkElt.href = url.toString()
    }
  }

  eventRender = (info) => {
    let $el = $(info.el);
    let extendedProps = info.event.extendedProps;

    if (extendedProps.past == true) {
      $el.addClass("fc-event-past");
    };
    if (extendedProps.duration <= 30) {
      $el.addClass("fc-event-small");
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
    }

    $el.attr("title", title);
    $el.attr("data-toggle", "tooltip");
    $el.attr("data-html", "true");
    $el.tooltip()
  }

  isTodayVisible = ({ activeStart, activeEnd }) => {
    const now = new Date()
    return now >= activeStart && now <= activeEnd;
  }

  handleAjaxError = () => {
    alert("Le chargement du calendrier a échoué; un rapport d’erreur a été transmis à l’équipe.\nRechargez la page, et si ce problème persiste, contactez-nous à support@rdv-solidarites.fr.");
  }
}

document.addEventListener('turbolinks:load', function () {
  new CalendarRdvSolidarites()
});

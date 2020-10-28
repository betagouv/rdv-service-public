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
    this.refreshCalendarInterval = setInterval(() => this.fullCalendarInstance.refetchEvents(), 30000)
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
      eventSourceFailure: function (errorObj) {
        alert("Une erreur s'est produite lors de la récupération des données du calendrier.");
      },
      defaultDate: this.getDefaultDate(),
      defaultView: this.getDefaultView(),
      viewSkeletonRender: function (info) {
        localStorage.setItem("calendarDefaultView", info.view.type);
      },
      weekends: false,
      height: "auto",
      selectable: true,
      select: this.selectEvent,
      header: {
        center: 'dayGridMonth,timeGridWeek,timeGridOneDay'
      },
      views: {
        timeGridOneDay: {
          type: 'timeGrid',
          duration: { days: 1 },
          buttonText: 'Journée'
        }
      },
      timeGridEventMinHeight: 15,
      businessHours: {
        // days of week. an array of zero-based day of week integers (0=Sunday)
        daysOfWeek: [1, 2, 3, 4, 5],
        startTime: '07:00',
        endTime: '19:00',
      },
      minTime: '07:00:00',
      maxTime: '20:00:00',
      datesRender: this.datesRender,
      eventRender: this.eventRender,
      eventMouseLeave: (info) => $(info.el).tooltip('hide') // extra security
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
    if ($('body').hasClass('right-bar-enabled')) return false;

    let startDate = moment(info.start);
    const urlSearchParams = new URLSearchParams({
      starts_at: info.startStr,
      "agent_ids[]": this.data.agentId,
    });
    let plage_ouvertures = this.fullCalendarInstance.getEvents()
      .filter(e => e.rendering == "background")
      .filter(e => startDate.isBetween(e.start, e.end, null, "[]"));

    if (plage_ouvertures[0] !== undefined) {
      urlSearchParams.append('plage_ouverture_location', plage_ouvertures[0].extendedProps.location);
    }
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
    printLinkElt.classList.toggle("d-none", info.view.type != "timeGridOneDay")
    if (info.view.type != "timeGridOneDay") return

    const url = new URL(printLinkElt.href)
    const date = moment(info.view.currentStart)
    printLinkElt.querySelector(".js-date").innerHTML = date.format("DD/MM/YYYY")
    url.searchParams.set("date", date.format("YYYY-MM-DD"))
    printLinkElt.href = url.toString()
  }

  eventRender = (info) => {
    let $el = $(info.el);
    if(info.event.extendedProps.past == true) {
      $el.addClass("fc-event-past");
    };
    if(info.event.extendedProps.duration <= 30) {
      $el.addClass("fc-event-small");
    };
    if (this.data.selectedEventId && info.event.id == this.data.selectedEventId)
      $el.addClass("selected");
    $el.addClass("fc-event-"+ info.event.extendedProps.status);
    if (info.event.extendedProps.unclickable != true){
      let title = `${moment(info.event.start).format('H:mm')} - ${moment(info.event.end).format('H:mm')}`;
      if (info.event.rendering == 'background') {
        $el.append("<div class=\"fc-title\" style=\"color: white; padding: 2px 4px; font-size: 12px; font-weight: bold;\">" + info.event.title + "</div>");

        title += `<br><strong>${info.event.title}</strong><br> <small>Lieu : ${info.event.extendedProps.lieu}</small>`;
      } else {
        if (info.event.extendedProps.duration) {
          title += ` <small>(${info.event.extendedProps.duration} min)</small>`;
          title += ` <br>${info.event.extendedProps.motif}`;
        }
        title += `<br><strong>${info.event.title}</strong>`;
        title += `<br><strong>Statut:</strong> ${info.event.extendedProps.readableStatus}`;
      }

      $el.attr("title", title);
      $el.attr("data-toggle", "tooltip");
      $el.attr("data-html", "true");
      $el.tooltip()
    }
  }

  isTodayVisible = ({ activeStart, activeEnd }) => {
    const now = new Date()
    return now >= activeStart && now <= activeEnd;
  }
}

document.addEventListener('turbolinks:load', function() {
  new CalendarRdvSolidarites()
});

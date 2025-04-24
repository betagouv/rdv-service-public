import { Calendar } from '@fullcalendar/core';
import dayGridPlugin from '@fullcalendar/daygrid';
import timeGridPlugin from '@fullcalendar/timegrid';
import listPlugin from '@fullcalendar/list';
import interactionPlugin from '@fullcalendar/interaction';
import { defaultFullCalendarConfig, eventRenderer } from  './calendar/utils'

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
    this.pollingButtonEl = document.getElementById("js-calendar-polling");
    this.pollingButtonEl?.addEventListener("click", () => {
      this.pollingButtonEl.dataset["enabled"] ? this.disablePolling() : this.enablePolling()
    })

    document.addEventListener('turbolinks:before-cache', this.disablePolling);
    document.addEventListener('turbolinks:before-render', this.enablePolling);
    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'visible') {
        // when agent comes back to tab, refresh immediately
        this.fullCalendarInstance.refetchEvents();

        this.enablePolling();
      } else if (this.refreshCalendarInterval) {
        this.disablePolling();
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
    this.enablePolling()
  }

  disablePolling = () => {
    if (this.refreshCalendarInterval) {
      clearTimeout(this.refreshCalendarInterval)
      this.refreshCalendarInterval = null
    }
    this.pollingButtonEl.innerHTML = "Mettre à jour automatiquement"
    this.pollingButtonEl.classList.remove("fr-icon-pause-circle-line")
    this.pollingButtonEl.classList.add("fr-icon-play-circle-line")
    this.pollingButtonEl.removeAttribute("data-enabled")
  }

  enablePolling = () => {
    if (!this.refreshCalendarInterval) {
      this.refreshCalendarInterval = setInterval(() => this.fullCalendarInstance.refetchEvents(), 1000)
    }
    this.pollingButtonEl.innerHTML = "Arrêter la mise à jour automatique"
    this.pollingButtonEl.classList.remove("fr-icon-play-circle-line")
    this.pollingButtonEl.classList.add("fr-icon-pause-circle-line")
    this.pollingButtonEl.setAttribute("data-enabled", "true")
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
      plugins: [dayGridPlugin, timeGridPlugin, listPlugin, interactionPlugin],
      eventSources: JSON.parse(this.data.eventSourcesJson),
      eventSourceFailure: this.handleAjaxError,
      defaultDate: this.getDefaultDate(),
      defaultView: this.getDefaultView(),
      viewSkeletonRender: function (info) {
        localStorage.setItem("calendarDefaultView", info.view.type);
      },
      hiddenDays: hiddenDays,
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
      datesRender: this.datesRender,
      eventRender: eventRenderer(this.data.selectedEventId),
    }
    return new Calendar(this.calendarEl, { ...defaultFullCalendarConfig(), ...options });
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

  isTodayVisible = ({ activeStart, activeEnd }) => {
    const now = new Date()
    return now >= activeStart && now <= activeEnd;
  }

  handleAjaxError = (response) => {
    if (response.xhr.status === 401) {
      window.location = this.calendarEl.attributes["data-sign-in-path"].value;
      return;
    }

    alert(`Le chargement du calendrier a échoué; un rapport d’erreur a été transmis à l’équipe.\nRechargez la page, et si ce problème persiste, contactez-nous à support@rdv-service-public.fr.`);
  }
}

document.addEventListener('turbolinks:load', function () {
  new CalendarRdvSolidarites()
});

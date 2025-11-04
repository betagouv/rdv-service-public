import { Calendar } from "@fullcalendar/core";
import resourceTimegridPlugin from "@fullcalendar/resource-timegrid";
import interactionPlugin from "@fullcalendar/interaction";
import { defaultFullCalendarConfig, eventRenderer, setupRefresh, handleAjaxError } from "./utils";

class AgendaMultiAgent {
  constructor() {
    this.calendarEl = document.querySelector("#agenda-multi-agent");
    if (this.calendarEl == null || this.calendarEl.innerHTML !== "") {
      return;
    }

    this.data = this.calendarEl.dataset
    this.fullCalendarInstance = this.initFullCalendar(this.calendarEl)
    this.fullCalendarInstance.render();
    setupRefresh(this.fullCalendarInstance);
  }
  initFullCalendar = () => {
    const hiddenDays = []
    if (this.data.displaySaturdays !== "true") {
      hiddenDays.push(6);
    }
    if (this.data.displaySundays !== "true") {
      hiddenDays.push(0);
    }
    const options = {
      plugins: [resourceTimegridPlugin, interactionPlugin],
      schedulerLicenseKey: "GPL-My-Project-Is-Open-Source",
      resources: JSON.parse(this.data.resourcesJson),
      eventSources: JSON.parse(this.data.eventSourcesJson),
      eventSourceFailure: handleAjaxError,
      initialView: localStorage.getItem("chosenCalendarView") || "resourceTimeGridDay",
      initialDate: localStorage.getItem("chosenCalendarDay"),
      headerToolbar: {
        center: 'resourceTimeGridDay,resourceTimeGridTwoDays,resourceTimeGridThreeDays,resourceTimeGridFourDays,resourceTimeGridFiveDays'
      },
      datesAboveResources: true,
      datesSet: this.datesSet,
      hiddenDays: hiddenDays,
      select: this.selectEvent,
      eventDidMount: eventRenderer(),
      views: {

        resourceTimeGridDay: {
          buttonText: "1 jour",
          titleFormat: { weekday: "long", day: "numeric", month: "long", year: "numeric" }
        },
      
        resourceTimeGridTwoDays: {
          type: "resourceTimeGrid",
          dayCount: 2,
          buttonText: "2 jours",
          titleFormat: { weekday: "long", day: "numeric", month: "short", year: "numeric" }
        },

        resourceTimeGridThreeDays: {
          type: "resourceTimeGrid",
          dayCount: 3,
          buttonText: "3 jours",
          titleFormat: { weekday: "long", day: "numeric", month: "short", year: "numeric" }
        },
      
        resourceTimeGridFourDays: {
          type: "resourceTimeGrid",
          dayCount: 4,
          buttonText: "4 jours",
          titleFormat: { weekday: "long", day: "numeric", month: "short", year: "numeric" }
        },

        resourceTimeGridFiveDays: {
          type: "resourceTimeGrid",
          dayCount: 5,
          buttonText: "5 jours",
          titleFormat: { weekday: "long", day: "numeric", month: "short", year: "numeric" }
        },

      },
    };
    return new Calendar(this.calendarEl, { ...defaultFullCalendarConfig(), ...options });
  }

  selectEvent = (info) => {
    const urlSearchParams = new URLSearchParams({
      starts_at: info.startStr,
      "agent_ids[]": info.resource.id,
    });
    window.location = `/admin/organisations/${this.data.organisationId}/rdv_wizard_step/new?${urlSearchParams.toString()}`;
  }
 
  datesSet = (info) => {
    localStorage.setItem("chosenCalendarView", info.view.type);
    localStorage.setItem("chosenCalendarDay", info.startStr?.split("T")[0]);
  }
}

export { AgendaMultiAgent }

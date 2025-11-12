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
      initialView: "resourceTimeGridDay",
      hiddenDays: hiddenDays,
      select: this.selectEvent,
      eventDidMount: eventRenderer(),
      views: {
        resourceTimeGridDay: {
          titleFormat: {
            month: 'long',
            year: 'numeric',
            day: 'numeric',
            weekday: 'long'
          },
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
}

export { AgendaMultiAgent }

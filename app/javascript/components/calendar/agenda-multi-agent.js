import { Calendar } from "@fullcalendar/core";
import resourceTimegridPlugin from "@fullcalendar/resource-timegrid";
import interactionPlugin from "@fullcalendar/interaction";
import { defaultFullCalendarConfig, eventRenderer } from "./utils";
import { handleAjaxError } from "../calendar"

class AgendaMultiAgent {
  constructor() {
    this.calendarEl = document.querySelector("#agenda-multi-agent");
    if (this.calendarEl == null || this.calendarEl.innerHTML !== "") {
      return;
    }

    this.data = this.calendarEl.dataset
    this.fullCalendarInstance = this.initFullCalendar(this.calendarEl)
    this.fullCalendarInstance.render();
  }
  initFullCalendar = () => {
    const fullCalendarConfigFromServer = JSON.parse(this.data.fullCalendarConfigFromServerJson);

    const options = {
      ...fullCalendarConfigFromServer,
      plugins: [resourceTimegridPlugin, interactionPlugin],
      schedulerLicenseKey: "GPL-My-Project-Is-Open-Source",
      eventSourceFailure: handleAjaxError,
      initialView: "resourceTimeGridDay",
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

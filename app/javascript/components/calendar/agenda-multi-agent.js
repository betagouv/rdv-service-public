import { Calendar } from '@fullcalendar/core';
import resourceTimegridPlugin from '@fullcalendar/resource-timegrid';
import interactionPlugin from '@fullcalendar/interaction';
import {defaultFullCalendarConfig, eventRenderer} from "./utils";
import {handleAjaxError} from "../calendar"

class AgendaMultiAgent {
  constructor() {
    this.calendarEl = document.querySelector('#agenda-multi-agent');
    if (this.calendarEl == null || this.calendarEl.innerHTML !== "") {
      return;
    }

    this.data = this.calendarEl.dataset
    this.fullCalendarInstance = this.initFullCalendar(this.calendarEl)
    this.fullCalendarInstance.render();
  }
  initFullCalendar = () => {
    const options = {
      plugins: [resourceTimegridPlugin, interactionPlugin],
      schedulerLicenseKey: "GPL-My-Project-Is-Open-Source",
      resources: JSON.parse(this.data.resourcesJson),
      eventSources: JSON.parse(this.data.eventSourcesJson),
      eventSourceFailure: handleAjaxError,
      // initialDate: this.getDefaultDate(),
      initialView: "resourceTimeGridDay",
      select: this.selectEvent,
      // headerToolbar: {
      //   center: 'resourceTimeGridDay'
      // },
      eventDidMount: eventRenderer(this.data.selectedEventId),
    }
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

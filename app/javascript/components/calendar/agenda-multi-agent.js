import { Calendar } from '@fullcalendar/core';
import resourceTimegridPlugin from '@fullcalendar/resource-timegrid';
import interactionPlugin from '@fullcalendar/interaction';
import {defaultFullCalendarConfig, eventRenderer} from "./utils";

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
      // eventSourceFailure: this.handleAjaxError,
      // initialDate: this.getDefaultDate(),
      initialView: "resourceTimeGridDay",
      select: () => {
        alert("oui oui")
      },
      // headerToolbar: {
      //   center: 'resourceTimeGridDay'
      // },
      eventDidMount: eventRenderer(this.data.selectedEventId),
    }
    return new Calendar(this.calendarEl, { ...defaultFullCalendarConfig(), ...options });
  }
}

document.addEventListener('turbolinks:load', function () {
  new AgendaMultiAgent();
});

import { Controller } from "@hotwired/stimulus"

import { Calendar } from '@fullcalendar/core';
import timeGridPlugin from '@fullcalendar/timegrid';
import interactionPlugin from '@fullcalendar/interaction';
import { defaultFullCalendarConfig, eventRenderer } from '../components/calendar/utils'

export default class extends Controller {
  connect() {
    const calendarEl = document.getElementById('rdvPlanCalendar');
    if (calendarEl == null || calendarEl.innerHTML !== "")
      return

    this.calendar = new Calendar(calendarEl, this.calendarConfig(calendarEl.dataset))
    this.calendar.render();
  }

  updateAgent(event) {
    const agentId = event.target.value
    fetch(`/agents/rdv_plans/${this.data.element.getAttribute("data-rdv-plan-id")}/update_agent?rdv_plan[rdv_agent_id]=${agentId}`, {
      method: "PATCH",
      headers: {
        "Accept": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').getAttribute("content")
      }
    }).then(response => {
      if (response.ok) {
        response.json().then(data => {
          this.removeEventSources()
          this.addEventSources(data.event_sources)
        })
      } else {
        throw new Error("Network response was not ok")
      }
    })
  }

  removeEventSources() {
    if (this.calendar) {
      this.calendar.getEventSources().forEach(eventSource => eventSource.remove())
    }
  }

  addEventSources(eventSources) {
    if (this.calendar) {
      eventSources.forEach(eventSource => this.calendar.addEventSource(eventSource))
    }
  }

  calendarConfig = (dataset) => {
    const fullCalendarConfigFromServer = JSON.parse(this.data.fullCalendarConfigFromServerJson);

    const options = {
      ...fullCalendarConfigFromServer,
      plugins: [timeGridPlugin, interactionPlugin],
      initialDate: JSON.parse(dataset.defaultDateJson),
      initialView: dataset.singleDay === "true" ? 'timeGridDay' : 'timeGridWeek',
      headerToolbar: { left:  '', center: '', right:  '' },
      select: this.selectEvent,
      slotMinTime: dataset.slotMinTime || '07:00:00',
      slotMaxTime: dataset.slotMaxTime || '20:00:00',
      eventDidMount: eventRenderer(),
    }

    if (dataset.singleDay !== "true") {
      options.headerToolbar.right = 'prev,next';
    }

    return { ...defaultFullCalendarConfig(), ...options };
  }

  selectEvent = (info) => {
    document.getElementById('rdvPlanCalendarField').value = info.startStr
    document.getElementById('rdvPlanCalendarForm').submit()
  }
}

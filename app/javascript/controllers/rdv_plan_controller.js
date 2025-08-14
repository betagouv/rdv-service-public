import { Controller } from "@hotwired/stimulus"

import {RdvPlanCalendar} from "../components/rdv-plan-calendar";

export default class extends Controller {
  connect() {
    this.calendar = new RdvPlanCalendar()
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
}
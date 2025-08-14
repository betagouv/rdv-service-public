import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
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
        console.log(response.json())
      } else {
        throw new Error("Network response was not ok")
      }
    })
  }
}
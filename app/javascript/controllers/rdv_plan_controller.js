import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("CONNECT RDV PLAN CONTROLLER")
  }

  updateAgent(event) {
    console.log("update agent")
    const agentId = event.target.value
    console.log(agentId)
    console.log(this.data.element.getAttribute("data-rdv-plan-id"))
    fetch(`/agents/rdv_plans/${this.data.element.getAttribute("data-rdv-plan-id")}/update_agent?rdv_plan[rdv_agent_id]=${agentId}`, {
      method: "PATCH",
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').getAttribute("content")
      }
    }).then(r => r.text())
      .then(html => {
        Turbo.renderStreamMessage(html)
      })
  }
}
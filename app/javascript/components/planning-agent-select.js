// See also AgentsHelper::planning_agent_select
class PlanningAgentSelect {
  constructor() {
    // have to use jQuery here because of select2
    this.$select = $(".js-planning-agent-select")
    if (!this.$select) return

    this.$select.on("change", this.agentSelected)
  }

  agentSelected = (event) => {
    // Make sure to stay on the same subsection (Agenda, PlageOuverture, Absence) when switching to another agent:
    // build the url dynamically from the passed template and the agent id.
    let url = this.$select[0].dataset.urlTemplate;
    let agent_id = this.$select.select2("data")[0].element.value;
    url = url.replace("__AGENT__", agent_id)
    window.location = url
  }
}

export { PlanningAgentSelect }

class PlanningAgentSelect {
  constructor() {
    // have to use jQuery here because of select2
    this.$select = $(".js-planning-agent-select")
    if (!this.$select) return

    this.$select.on("change", this.agentSelected)
  }

  agentSelected = (event) =>
    Turbolinks.visit(this.$select.select2("data")[0].element.dataset.url)
}

export { PlanningAgentSelect }

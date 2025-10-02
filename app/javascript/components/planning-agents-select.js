import { initInput } from "./select2-inputs"

export const planningAgentsSelect = () => {
  if(!document.querySelector("#planning_agents_select")) {
    return;
  }
  const agentSelect = document.querySelector("#agent_id");
  const multiAgentEnableButton = document.querySelector("#multi_agent_enable");

  if(!agentSelect.multiple) {
    $(agentSelect).on("change", event => event.target.form.submit());
  }

  multiAgentEnableButton.addEventListener("click", (e) => {
    e.preventDefault();
    agentSelect.multiple = true;
    initInput(agentSelect);
    multiAgentEnableButton.classList.add("hidden");
    document.querySelector("#submit_agents").classList.remove("hidden");
  });
}

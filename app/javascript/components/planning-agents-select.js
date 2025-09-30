import { initInput } from "./select2-inputs"

export const planningAgentsSelect = () => {
  const agentSelect = document.querySelector("#agent_id");
  const multiAgentEnableButton = document.querySelector("#multi_agent_enable");
  const submit = document.querySelector("#submit_agents");
  if(!multiAgentEnableButton) {
    return;
  }

  multiAgentEnableButton.addEventListener("click", (e) => {
    e.preventDefault();
    agentSelect.multiple = true;
    agentSelect.dataset.action = null; // On retire "change->form#submit"
    initInput(agentSelect);
    multiAgentEnableButton.classList.add("hidden");
    submit.classList.remove("hidden");
  });
}

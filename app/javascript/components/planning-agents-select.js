import { initInput } from "./select2-inputs"

const planningAgentsSelect = () => {
  const agentSelect = document.querySelector("#agent_id");
  const toggle = document.querySelector("#multi_agent_toggle");
  const submit = document.querySelector("#submit_agents");
  if(!toggle) {
    return;
  }

  toggle.addEventListener("click", (e) => {
    e.preventDefault();
    agentSelect.multiple = true;
    agentSelect.onchange = "";
    initInput(agentSelect);
    toggle.classList.add("hidden");
    submit.classList.remove("hidden");
  });
}

export { planningAgentsSelect }

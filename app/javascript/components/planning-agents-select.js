import { initInput } from "./select2-inputs"

export const planningAgentsSelect = () => {
  if(!document.querySelector("#planning_agents_select")) {
    return;
  }
  const agentSelect = document.querySelector("#agent_id");
  const multiAgentEnableButton = document.querySelector("#multi_agent_enable");

  if(!agentSelect.multiple) {
    $(agentSelect).on("change", (event) => {
      // On doit re-vérifier ici car le champ peut devenir multiple via JS (ci-dessous),
      // mais cette fonction de callback d'event est toujours bindée.
      if(!agentSelect.multiple) {
        event.target.form.submit();
      }
    });
  }

  if(!multiAgentEnableButton) {
    return;
  }

  multiAgentEnableButton.addEventListener("click", (e) => {
    e.preventDefault();
    agentSelect.multiple = true;
    initInput(agentSelect);
    multiAgentEnableButton.classList.add("hidden");
    document.querySelector("#submit_agents").classList.remove("hidden");

    // Pas la place pour le toggle quand plusieurs agents sont sélectionnés
    document.querySelectorAll(".js-new-planning-toggle").forEach(elem => {
      elem.classList.remove("rdv-display-flex");
      elem.classList.add("hidden");
    })
  });
}

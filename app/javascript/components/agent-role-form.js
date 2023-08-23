class AgentRoleForm {
  constructor() {
    const formElt = document.querySelector('.js_agent_role_form')
    if (!formElt) return

    this.accessLevelRadios = formElt.querySelectorAll('input[name="agent[agent_role][access_level]"]')

    this.agentWithAccountFields = formElt.querySelectorAll('.js_agent_role_form__agent_with_account_fields')
    this.intervenantFields = formElt.querySelectorAll('.js_agent_role_form__intervenant_fields')

    this.updateFieldsDisplay()
    this.addEventListeners()
  }

  updateFieldsDisplay() {
    const selectedAccessLevel = [...this.accessLevelRadios].find(radio => radio.checked)?.value

    if (selectedAccessLevel === 'intervenant') {
      this.displayElementsAndEnableInputs(this.intervenantFields)
      this.hideElementsAndDisableInputs(this.agentWithAccountFields)
    } else {
      this.hideElementsAndDisableInputs(this.intervenantFields)
      this.displayElementsAndEnableInputs(this.agentWithAccountFields)
    }
  }

  displayElementsAndEnableInputs(elts) {
    elts.forEach(elt => {
      elt.style.display = 'block'
      elt.querySelectorAll('input').forEach((input) => {
        input.disabled = false
      })
    })
  }

  hideElementsAndDisableInputs(elts) {
    elts.forEach(elt => {
      elt.style.display = 'none'
      elt.querySelectorAll('input').forEach((input) => {
        input.disabled = true
      })
    })
  }

  addEventListeners() {
    this.accessLevelRadios.forEach(radio => {
      radio.addEventListener('change', () => this.updateFieldsDisplay())
    })
  }
}

export { AgentRoleForm }

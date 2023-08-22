class AgentRoleForm {
  constructor() {
    this.formElt = document.querySelector('.js_agent_form')
    if (!this.formElt) return

    this.originalAccessLevel = this.formElt.getAttribute('data-originalaccesslevel')

    this.accessLevelRadios = document.querySelectorAll('input[name="agent[agent_role][access_level]"]')
    this.agentWithAccountFields = document.querySelector('.js_agent_form__agent_with_account_fields')

    this.updateEmailFieldDisplay()
    this.addEventListeners()
  }

  updateEmailFieldDisplay() {
    const selectedAccessLevel = [...this.accessLevelRadios].find(radio => radio.checked)?.value
    const emailFieldShouldBeDisplayed = this.originalAccessLevel === 'intervenant' && selectedAccessLevel !== 'intervenant'
    if (emailFieldShouldBeDisplayed ) {

      this.agentWithAccountFields.style.display = 'block'
      this.agentWithAccountFields.querySelectorAll('input').forEach((input) => {
        input.disabled = false
      })
    } else {
      this.agentWithAccountFields.style.display = 'none'
      this.agentWithAccountFields.querySelectorAll('input').forEach((input) => {
        input.disabled = true
      })

    }
  }

  addEventListeners() {
    this.accessLevelRadios.forEach(radio => {
      radio.addEventListener('change', () => this.updateEmailFieldDisplay())
    })
  }
}

export { AgentRoleForm }

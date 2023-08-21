class AgentRoleForm {
  constructor() {
    this.formElt = document.querySelector('.js_agent_form')
    if (!this.formElt) return

    this.originalAccessLevel = this.formElt.getAttribute('data-originalaccesslevel')

    this.accessLevelRadios = document.querySelectorAll('input[name="agent[agent_role][access_level]"]')
    this.emailField = document.querySelector('.js_agent_form__email_field')

    this.updateEmailFieldDisplay()
    this.addEventListeners()
  }

  updateEmailFieldDisplay() {
    const selectedAccessLevel = [...this.accessLevelRadios].find(radio => radio.checked)?.value
    console.log(this.originalAccessLevel)
    console.log(selectedAccessLevel)
    const emailFieldShouldBeDisplayed = this.originalAccessLevel === 'intervenant' && selectedAccessLevel !== 'intervenant'
    this.emailField.style.display = emailFieldShouldBeDisplayed ? 'block' : 'none'
  }

  addEventListeners() {
    this.accessLevelRadios.forEach(radio => {
      radio.addEventListener('change', () => this.updateEmailFieldDisplay())
    })
  }
}

export { AgentRoleForm }

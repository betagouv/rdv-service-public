class AgentRoleForm {
  constructor() {
    this.formElt = document.querySelector('.edit_agent_role')
    if (!this.formElt) return

    this.originalAccessLevel = this.formElt.getAttribute('data-originalaccesslevel')

    this.accessLevelRadios = document.querySelectorAll('input[name="agent_role[access_level]"]')
    this.emailField = document.querySelector('#agent_email_input')

    this.updateEmailFieldDisplay()
    this.addEventListeners()
  }

  updateEmailFieldDisplay() {
    const selectedAccessLevel = [...this.accessLevelRadios].find(radio => radio.checked)?.value
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

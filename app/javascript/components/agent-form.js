class AgentForm {
  constructor() {
    this.formElt = document.querySelector('.js_agent_role_form')
    if (!this.formElt) return

    this.accessLevelRadios = document.querySelectorAll('input[name="agent[roles_attributes][0][access_level]"]')

    this.emailElements = document.querySelector('.js_agent_role_form__email_and_submit')
    this.lastNameElements = document.querySelector('.js_agent_role_form__last_name_and_submit')

    this.updateFieldsDisplay()
    this.addEventListeners()
  }

  updateFieldsDisplay() {
    console.log("update")
    const selectedAccessLevel = [...this.accessLevelRadios].find(radio => radio.checked)?.value

    this.emailElements.style.display = (selectedAccessLevel === 'basic' || selectedAccessLevel === 'admin') ? 'block' : 'none'

    this.lastNameElements.style.display = selectedAccessLevel === 'intervenant' ? 'block' : 'none'
  }

  addEventListeners() {
    this.accessLevelRadios.forEach(radio => {
      radio.addEventListener('change', () => this.updateFieldsDisplay())
    })
  }
}

export { AgentForm }


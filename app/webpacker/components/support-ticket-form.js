class SupportTicketForm {
  constructor() {
    this.subjectSelect = document.querySelector("select.js-support-ticket-form-subject")
    if (!this.subjectSelect) return

    this.subjectSelect.addEventListener('change', this.subjectChanged)
    this.subjectChanged()
  }

  subjectChanged = () => {
    const subjectRole = this.subjectSelect.value.startsWith("Je suis usager") ? "user" : "agent"
    document.
      querySelectorAll(".js-support-ticket-form-input-togglable").
      forEach(input => {
        const roleMatch = subjectRole === input.getAttribute('data-role')
        if (roleMatch)
          input.removeAttribute('disabled')
        else
          input.setAttribute('disabled', 'disabled')
        $(input).closest('div.form-group').toggleClass('d-none', !roleMatch)
      })
  }
}

export { SupportTicketForm }

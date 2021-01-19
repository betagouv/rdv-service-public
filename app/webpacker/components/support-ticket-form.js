class SupportTicketForm {
  constructor() {
    this.subjectSelect = document.querySelector("select.js-support-ticket-form-subject")
    if (!this.subjectSelect) return

    this.subjectSelect.addEventListener('change', this.subjectChanged)
    this.subjectChanged()
  }

  subjectChanged = () => {
    const isUserSubject = this.subjectSelect.value.startsWith("Je suis usager")
    document.
      querySelectorAll(".js-support-ticket-form-user-input").
      forEach(input => {
        if (isUserSubject)
          input.removeAttribute('disabled')
        else
          input.setAttribute('disabled', 'disabled')
        input.parentElement.parentElement.classList.toggle('d-none', !isUserSubject)
      })
  }
}

export { SupportTicketForm }

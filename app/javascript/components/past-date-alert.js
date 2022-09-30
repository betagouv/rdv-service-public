//
// Show an alert message under a date picker input, in case the selected date is in the past.
// This is using Stimulus-style data attributes for targets, in the hope we modernize our js stack.

class PastDateAlertController {
  constructor(container) {
    this.container = container
    this.alertMessage = null
    this.setupTargets()
    this.setupActions()
  }

  setupTargets() {
    this.dateInput = this.container.querySelector('[data-past-date-alert-target="date-input"]')
  }

  setupActions() {
    this.dateInput.addEventListener('focusout', e => { this.showAlertWhenDatePast(e.target.value) })
  }

  showAlertWhenDatePast(inputValue) {
    if (moment().isAfter(moment(inputValue, 'DD/MM/YYYY h:mm'))) {
      this.showAlertMessage()
    } else {
      this.hideAlertMessage()
    }
  }

  showAlertMessage() {
    if (this.alertMessage !== null) { return }

    this.alertMessage = this.buildAlertMessage()
    this.dateInput.parentNode.insertBefore(this.alertMessage, this.dateInput.nextSibling)
  }

  hideAlertMessage() {
    if (this.alertMessage === null) { return }

    this.dateInput.parentNode.removeChild(this.alertMessage)
    this.alertMessage = null
  }

  buildAlertMessage() {
    const message = document.createElement('small')
    message.classList.add('text-muted')
    message.textContent = '⚠️ Date dans le passé'
    return message
  }
}
class PastDateAlert {
  constructor() {
    document.querySelectorAll('[data-controller="past-date-alert"]').forEach(elt => new PastDateAlertController(elt))
  }
}

export { PastDateAlert }

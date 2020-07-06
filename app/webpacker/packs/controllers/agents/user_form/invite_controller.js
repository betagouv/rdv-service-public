import { Controller } from "stimulus"

// note: nested controllers are supposed to have independent scope but
// it was not working properly so I had to workaround it :/
export default class extends Controller {

  static targets = [ "emailInput", "inviteRow" ]

  connect() {
    this.attachChangeListeners()
    this.refreshVisibleFields()
  }

  attachChangeListeners = () => {
    this.emailInputTargets.forEach(elt =>
      elt.addEventListener("change", this.refreshVisibleFields)
    )
  }

  refreshVisibleFields = () => {
    this.inviteRowTargets.forEach(inviteRowElt => {
      const emailElt = inviteRowElt.parentElement.parentElement.
        querySelector("input[type=email]")
      inviteRowElt.classList.toggle("d-none", !emailElt.value)
    })
  }
}

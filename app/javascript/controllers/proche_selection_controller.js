import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["option"]

  connect() { this.update() }

  update() {
    this.optionTargets.forEach(option => {
      const toggle = option.querySelector("input[type=\"radio\"], input[type=\"checkbox\"]")
      if (!toggle) return
      const isChecked = toggle.checked
      const fields = option.querySelectorAll("input:not([type=\"radio\"]):not([type=\"checkbox\"]), select, textarea")
      fields.forEach(field => { field.disabled = !isChecked })
    })
  }
}

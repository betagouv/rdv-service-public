import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["newRelativeField", "newRelativeRadioButton"]

  connect() {
    this.toggle()
  }

  toggle() {
    const isChecked = this.newRelativeRadioButtonTarget.checked
    this.newRelativeFieldTargets.forEach(el => { el.disabled = !isChecked})
  }
}

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "locationTypeRadios",
    "bookableByRadios",
    "sectoSection",
    "secretariatSection",
    "secretariatCheckbox",
    "followUpCheckbox"
  ]

  connect() {
    // document.querySelector('#tab_resa_en_ligne').click();
    this.refreshSecto()
    this.refreshSecretariat()
  }

  refreshSecto() {
    if(this.bookableBy !== "agents" && !this.followUpCheckbox.checked) {
      this.sectoSectionTarget.classList.remove("disabled-card")
    }
    else {
      this.sectoSectionTarget.classList.add("disabled-card")
    }
  }
  refreshSecretariat() {
    if(this.locationType !== "home" && !this.followUpCheckbox.checked) {
      this.secretariatSectionTarget.classList.remove("disabled-card")
      this.secretariatCheckbox.disabled = false
    }
    else {
      this.secretariatSectionTarget.classList.add("disabled-card")
      this.secretariatCheckbox.disabled = true
      this.secretariatCheckbox.checked = false
    }
  }

  get locationType() {
    return this.locationTypeRadiosTargets.find(radio => radio.checked).value
  }
  get bookableBy() {
    return this.bookableByRadiosTargets.find(radio => radio.checked).value
  }
  get secretariatCheckbox() {
    return this.secretariatCheckboxTarget
  }
  get followUpCheckbox() {
    return this.followUpCheckboxTarget
  }
}

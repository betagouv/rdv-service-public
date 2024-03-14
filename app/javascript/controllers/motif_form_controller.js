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
    if(this.sectoShouldBeEnabled()) {
      this.enableSection(this.sectoSectionTarget)
    }
    else {
      this.disableSection(this.sectoSectionTarget)
    }
  }
  refreshSecretariat() {
    if(this.secretariatShouldBeEnabled()) {
      this.enableSection(this.secretariatSectionTarget)
    }
    else {
      this.disableSection(this.secretariatSectionTarget)
      this.secretariatCheckbox.checked = false
    }
  }

  sectoShouldBeEnabled() {
    return this.bookableBy !== "agents" && !this.followUpCheckbox.checked
  }

  secretariatShouldBeEnabled() {
    return this.locationType !== "home" && !this.followUpCheckbox.checked
  }

  enableSection(sectionRoot) {
    sectionRoot.classList.remove("disabled-card")
    sectionRoot.querySelectorAll("input, select").forEach(i => i.disabled = false)
  }
  disableSection(sectionRoot) {
    sectionRoot.classList.add("disabled-card")
    sectionRoot.querySelectorAll("input, select").forEach(i => i.disabled = true)
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

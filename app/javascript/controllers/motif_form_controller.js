import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "locationTypeRadios",
    "secretariatSection",
    "followUpCheckbox"
  ]

  connect() {
    this.refreshSections(null)
  }

  refreshSections(event) {
    const resetCheckbox = !!event;
    this.refreshSection(this.secretariatSectionTarget, this.shouldDisableSecretariat(), resetCheckbox)
  }

  refreshSection(section, disable, resetCheckbox) {
    if(disable) {
      $(sectionRoot).collapse("hide")
    }
    else {
      $(section).collapse("show")
    }
  }

  shouldDisableSecretariat() {
    return this.locationType === "home" || this.followUpCheckbox.checked
  }

  get locationType() {
    return this.locationTypeRadiosTargets.find(radio => radio.checked).value
  }
  get followUpCheckbox() {
    return this.followUpCheckboxTarget
  }
}

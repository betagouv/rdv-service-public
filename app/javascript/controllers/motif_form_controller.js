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
      this.disableSection(section, resetCheckbox)
    }
    else {
      this.enableSection(section, resetCheckbox)
    }
  }

  shouldDisableSecretariat() {
    return this.locationType === "home" || this.followUpCheckbox.checked
  }

  enableSection(sectionRoot, resetCheckbox) {
    $(sectionRoot).collapse("show")
    if(resetCheckbox) {
      sectionRoot.querySelectorAll(".js-check-on-section-enable").forEach(box => box.checked = true)
    }
  }
  disableSection(sectionRoot, resetCheckbox) {
    $(sectionRoot).collapse("hide")
    if(resetCheckbox) {
      sectionRoot.querySelectorAll(".js-uncheck-on-section-disable").forEach(box => box.checked = false)
    }
  }

  get locationType() {
    return this.locationTypeRadiosTargets.find(radio => radio.checked).value
  }
  get followUpCheckbox() {
    return this.followUpCheckboxTarget
  }
}

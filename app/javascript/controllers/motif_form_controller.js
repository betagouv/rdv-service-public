import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "locationTypeRadios",
    "bookableByRadios",
    "bookingDelaySection",
    "sectoSection",
    "secretariatSection",
    "followUpCheckbox"
  ]

  connect() {
    this.refreshSections(null)

    // Permet de pointer vers l'onglet de résa en ligne via un lien avec ancre
    if(window.location.hash === "#tab_resa_en_ligne") {
      this.element.querySelector("button#tab_resa_en_ligne").click();
    }
  }

  refreshSections(event) {
    const resetCheckbox = !!event;
    this.refreshSection(this.bookingDelaySectionTarget, this.shouldDisableBookingDelay(), resetCheckbox)
    this.refreshSection(this.sectoSectionTarget, this.shouldDisableSecto(), resetCheckbox)
    this.refreshSection(this.secretariatSectionTarget, this.shouldDisableSecretariat(), resetCheckbox)
  }

  refreshSection(section, disable, resetCheckbox) {
    if(disable) {
      this.enableSection(section, resetCheckbox)
    }
    else {
      this.disableSection(section, resetCheckbox)
    }
  }

  shouldDisableBookingDelay() {
    return this.bookableBy === "agents"
  }

  shouldDisableSecto() {
    return this.bookableBy === "agents" || this.followUpCheckbox.checked
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
  get bookableBy() {
    return this.bookableByRadiosTargets.find(radio => radio.checked).value
  }
  get followUpCheckbox() {
    return this.followUpCheckboxTarget
  }
}

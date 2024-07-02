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
    this.refreshSection(this.bookingDelaySectionTarget, this.reasonsToDisableBookingDelay(), resetCheckbox)
    this.refreshSection(this.sectoSectionTarget, this.reasonsToDisableSecto(), resetCheckbox)
    this.refreshSection(this.secretariatSectionTarget, this.reasonsToDisableSecretariat(), resetCheckbox)
  }

  refreshSection(section, reasons, resetCheckbox) {
    if(reasons.length === 0) {
      this.enableSection(section, resetCheckbox)
    }
    else {
      this.disableSection(section, reasons, resetCheckbox)
    }
  }

  reasonsToDisableBookingDelay() {
    return this.bookableBy === "agents" ? ["les créneaux ne sont pas ouverts à la réservation en ligne"] : []
  }

  reasonsToDisableSecto() {
    const reasons = []
    if(this.bookableBy === "agents") {
      reasons.push("les créneaux ne sont pas ouverts à la réservation en ligne")
    }
    if(this.followUpCheckbox.checked) {
      reasons.push(`l'option "RDV de suivi" est cochée`)
    }
    return reasons
  }

  reasonsToDisableSecretariat() {
    const reasons = []
    if(this.locationType === "home") {
      reasons.push("le RDV est à domicile")
    }
    if(this.followUpCheckbox.checked) {
      reasons.push(`l'option "RDV de suivi" est cochée`)
    }
    return reasons
  }

  enableSection(sectionRoot, resetCheckbox) {
    $(sectionRoot).collapse("show")
    sectionRoot.querySelectorAll("input:not([type=hidden]), select").forEach(i => i.disabled = false)
    if(resetCheckbox) {
      sectionRoot.querySelectorAll(".js-check-on-section-enable").forEach(box => box.checked = true)
    }
    sectionRoot.querySelector(".js-reasons-for-disabled-section").classList.add("hidden")
    sectionRoot.classList.remove("disabled-card")
  }
  disableSection(sectionRoot, reasons, resetCheckbox) {
    $(sectionRoot).collapse("hide")
    sectionRoot.querySelectorAll("input:not([type=hidden]), select").forEach(i => i.disabled = true)
    if(resetCheckbox) {
      sectionRoot.querySelectorAll(".js-uncheck-on-section-disable").forEach(box => box.checked = false)
    }
    sectionRoot.querySelector(".js-reasons-for-disabled-section").innerText = `Vous ne pouvez pas modifier ce paramètre car ${reasons.join(" et ")}.`;
    sectionRoot.querySelector(".js-reasons-for-disabled-section").classList.remove("hidden")
    sectionRoot.classList.add("disabled-card")
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

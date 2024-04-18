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
    this.refreshSections()

    // Permet de pointer vers l'onglet de résa en ligne via un lien avec ancre
    if(window.location.hash === "#tab_resa_en_ligne") {
      this.element.querySelector("button#tab_resa_en_ligne").click();
    }
  }

  refreshSections() {
    this.refreshSection(this.bookingDelaySectionTarget, this.reasonsToDisableBookingDelay())
    this.refreshSection(this.sectoSectionTarget, this.reasonsToDisableSecto())
    this.refreshSection(this.secretariatSectionTarget, this.reasonsToDisableSecretariat())
  }

  refreshSection(section, reasons) {
    if(reasons.length === 0) {
      this.enableSection(section)
    }
    else {
      this.disableSection(section, reasons)
    }
  }

  reasonsToDisableBookingDelay() {
    return this.bookableBy === "agents" ? ["les créneaux sont ne sont pas ouverts à la réservation en ligne"] : []
  }

  reasonsToDisableSecto() {
    const reasons = []
    if(this.bookableBy === "agents") {
      reasons.push("les créneaux sont ne sont pas ouverts à la réservation en ligne")
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

  enableSection(sectionRoot) {
    sectionRoot.querySelectorAll("input, select").forEach(i => i.disabled = false)
    sectionRoot.querySelector(".js-reasons-for-disabled-section").classList.add("hidden")
    sectionRoot.querySelectorAll(".js-check-on-section-enable").forEach(box => box.checked = true)
    sectionRoot.classList.remove("disabled-card")
  }
  disableSection(sectionRoot, reasons) {
    sectionRoot.querySelectorAll("input, select").forEach(i => i.disabled = true)
    sectionRoot.querySelector(".js-reasons-for-disabled-section").innerText = `Vous ne pouvez pas modifier ce paramètre si ${reasons.join(" ou ")}.`;
    sectionRoot.querySelector(".js-reasons-for-disabled-section").classList.remove("hidden")
    sectionRoot.querySelectorAll(".js-uncheck-on-section-disable").forEach(box => box.checked = false)
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

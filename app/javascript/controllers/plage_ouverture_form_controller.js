import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "motifsSection",
    "dateAndTimeSection",
    "labelSection",
    "submitSection",
  ]

  showMotifsSection() {
    this.motifsSectionTarget.hidden = false;
  }

  showAllSections() {
    this.motifsSectionTarget.hidden = false;
    this.dateAndTimeSectionTarget.hidden = false;
    this.labelSectionTarget.hidden = false;
    this.submitSectionTarget.hidden = false;
  }
}

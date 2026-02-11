import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "motifsSection",
    "dateAndTimeSection",
    "recurrenceCheckbox",
    "labelSection",
    "submitSection",
  ]

  enableRecurrence() {
    this.recurrenceCheckboxTarget.checked = true;
    this.recurrenceCheckboxTarget.dispatchEvent(new Event('change'))
    document.querySelector('label[for="recurrence-source"]').childNodes.filter(child => child.nodeType === Node.TEXT_NODE).forEach((node) => {
      node.textContent = "Premier jour"
    });
  }

  disableRecurrence() {
    this.recurrenceCheckboxTarget.checked = false;
    this.recurrenceCheckboxTarget.dispatchEvent(new Event('change'))
    document.querySelector('label[for="recurrence-source"]').childNodes.filter(child => child.nodeType === Node.TEXT_NODE).forEach((node) => {
      node.textContent = "Jour"
    });
  }

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

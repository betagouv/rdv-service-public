import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "motifsSection",
    "recurrencePickerSection",
    "dateAndTimeSection",
    "recurrenceCheckbox",
    "labelSection",
    "submitSection",
  ]

  connect() {
    if (this.motifsSectionTarget.querySelectorAll('input[name="plage_ouverture[motif_ids][]"]').length === 1) {
      this.showRecurrencePickerSection();
    }
  }

  enableRecurrence() {
    this.recurrenceCheckboxTarget.checked = true;
    this.recurrenceCheckboxTarget.dispatchEvent(new Event('change'))
    document.querySelector('label[for="recurrence-source"]').childNodes.forEach((node) => {
      if (node.nodeType === Node.TEXT_NODE) {
        node.textContent = "Premier jour"
      }
    });
  }

  disableRecurrence() {
    this.recurrenceCheckboxTarget.checked = false;
    this.recurrenceCheckboxTarget.dispatchEvent(new Event('change'))
    document.querySelector('label[for="recurrence-source"]').childNodes.forEach((node) => {
      if (node.nodeType === Node.TEXT_NODE) {
        node.textContent = "Date"
      }
    });
  }

  showRecurrencePickerSection() {
    this.recurrencePickerSectionTarget.hidden = false;
  }

  showAllSections() {
    this.motifsSectionTarget.hidden = false;
    this.dateAndTimeSectionTarget.hidden = false;
    this.labelSectionTarget.hidden = false;
    this.submitSectionTarget.hidden = false;
  }
}

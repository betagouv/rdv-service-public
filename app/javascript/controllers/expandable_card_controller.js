import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "toggle"]
  static values = { maxHeight: { type: Number, default: 400 } }

  connect() {
    this.expanded = false
    const needsCollapse = this.contentTarget.scrollHeight > this.maxHeightValue
    this.toggleTarget.hidden = !needsCollapse
    if (needsCollapse) {
      this.collapse()
    }
  }

  toggle() {
    this.expanded = !this.expanded
    if (this.expanded) {
      this.contentTarget.style.maxHeight = ""
      this.contentTarget.style.overflow = ""
      this.contentTarget.classList.remove("expandable-card--collapsed")
      this.toggleTarget.textContent = "Voir moins"
    } else {
      this.collapse()
      this.toggleTarget.textContent = "Voir plus"
    }
  }

  collapse() {
    this.contentTarget.style.maxHeight = `${this.maxHeightValue}px`
    this.contentTarget.style.overflow = "hidden"
    this.contentTarget.classList.add("expandable-card--collapsed")
  }
}

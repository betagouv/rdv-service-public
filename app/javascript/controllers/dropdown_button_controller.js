import { Controller } from "@hotwired/stimulus"

// Bouton déroulant accessible (pattern ARIA "disclosure").
// Markup : app/views/common/_dropdown_button.html.slim
//
// Le bouton ouvre/ferme la liste. Elle se ferme aussi avec Échap (le focus revient au bouton),
// par un clic à l'extérieur, ou quand le focus sort du composant (Tab).
export default class extends Controller {
  static targets = ["trigger", "list"]

  toggle() {
    this.#isOpen ? this.close() : this.#setOpen(true)
  }

  close(event) {
    if (!this.#isOpen) return
    this.#setOpen(false)
    if (event?.type === "keydown") this.triggerTarget.focus()
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  closeOnFocusOut(event) {
    if (event.relatedTarget && !this.element.contains(event.relatedTarget)) this.close()
  }

  get #isOpen() {
    return !this.listTarget.hidden
  }

  #setOpen(open) {
    this.listTarget.hidden = !open
    this.triggerTarget.setAttribute("aria-expanded", open)
  }
}

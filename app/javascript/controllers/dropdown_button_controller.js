import { Controller } from "@hotwired/stimulus"

// Bouton déroulant accessible (pattern ARIA "disclosure").
// Voir app/views/common/_dropdown_button.html.slim
//
// Clavier :
//  - Entrée / Espace (natif) : ouvre ou ferme
//  - Flèche bas sur le bouton : ouvre et place le focus sur la première action
//  - Flèches haut / bas, Début, Fin dans la liste : naviguent entre les actions
//  - Échap : ferme et rend le focus au bouton
//  - Tab hors du composant, ou clic à l'extérieur : ferme
export default class extends Controller {
  static targets = ["trigger", "list"]

  connect() {
    this.onOutsideClick = this.onOutsideClick.bind(this)
    this.onFocusOut = this.onFocusOut.bind(this)
    document.addEventListener("click", this.onOutsideClick)
    this.element.addEventListener("focusout", this.onFocusOut)
  }

  disconnect() {
    document.removeEventListener("click", this.onOutsideClick)
    this.element.removeEventListener("focusout", this.onFocusOut)
  }

  get isOpen() {
    return this.triggerTarget.getAttribute("aria-expanded") === "true"
  }

  get links() {
    return Array.from(this.listTarget.querySelectorAll("a, button"))
  }

  toggle() {
    this.isOpen ? this.close() : this.open()
  }

  open({ focusFirst = false } = {}) {
    this.triggerTarget.setAttribute("aria-expanded", "true")
    this.listTarget.hidden = false
    if (focusFirst) this.links[0]?.focus()
  }

  close({ returnFocus = false } = {}) {
    this.triggerTarget.setAttribute("aria-expanded", "false")
    this.listTarget.hidden = true
    if (returnFocus) this.triggerTarget.focus()
  }

  triggerKeydown(event) {
    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.open({ focusFirst: true })
    } else if (event.key === "Escape" && this.isOpen) {
      event.preventDefault()
      this.close({ returnFocus: true })
    }
  }

  listKeydown(event) {
    const links = this.links
    const index = links.indexOf(document.activeElement)
    const moves = {
      ArrowDown: (index + 1) % links.length,
      ArrowUp: (index - 1 + links.length) % links.length,
      Home: 0,
      End: links.length - 1,
    }

    if (event.key === "Escape") {
      event.preventDefault()
      this.close({ returnFocus: true })
    } else if (event.key in moves) {
      event.preventDefault()
      links[moves[event.key]].focus()
    }
  }

  onOutsideClick(event) {
    if (this.isOpen && !this.element.contains(event.target)) this.close()
  }

  // Ferme la liste quand le focus quitte complètement le composant (Tab / Maj+Tab).
  onFocusOut(event) {
    if (this.isOpen && event.relatedTarget && !this.element.contains(event.relatedTarget)) this.close()
  }
}

import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="proche-toggle"
// Gestion progressive de l'affichage des champs "proche" :
// - sans JS : liens de navigation visibles
// - avec JS : checkbox visible, liens cachés, navigation via Turbo Frame
export default class extends Controller {
  static targets = ["noJsToggle", "jsToggle"]
  static values = { enableUrl: String, disableUrl: String }

  connect() {
    this.noJsToggleTargets.forEach(el => el.style.display = "none")
    this.jsToggleTargets.forEach(el => el.style.display = "")
  }

  toggle(event) {
    event.target.disabled = true
    const url = event.target.checked ? this.enableUrlValue : this.disableUrlValue
    const frame = this.element.closest("turbo-frame")
    frame.src = url
    frame.reload()
  }
}

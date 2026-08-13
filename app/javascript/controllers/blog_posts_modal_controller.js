import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="blog-posts-modal"
export default class extends Controller {
  static targets = ["frame"]

  connect() {
    this.element.addEventListener("dsfr.disclose", this.load)
  }

  disconnect() {
    this.element.removeEventListener("dsfr.disclose", this.load)
  }

  // Charge le contenu du frame à l'ouverture de la modale plutôt qu'au chargement de la page :
  // le DSFR masque les modales avec visibility:hidden (et non display:none), ce qui empêche
  // l'IntersectionObserver utilisé par loading="lazy" de fonctionner comme attendu.
  load = () => {
    if (!this.frameTarget.src) {
      this.frameTarget.src = this.frameTarget.dataset.src
    }
  }
}

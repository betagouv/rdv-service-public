import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dependent-input"
export default class extends Controller {
  static targets = [
    "controllingInput",
    "dependentInputWrapper",
    "dependentInput"
  ]

  connect() {
    this.toggle()
  }

  toggle() {
    this.controllingInputTarget.checked ? this.show() : this.hide()
  }

  show() {
    window.dsfr(this.dependentInputWrapperTarget).collapse.disclose()
    this.dependentInputTarget.removeAttribute("disabled")
    // on veut que le champ qui apparaît soit required, mais on ne veut pas le mettre dans le HTML nu
    // pour ne pas bloquer la version sans JS. Pas besoin de l’unset car ça n’impacte pas les input disabled
    this.dependentInputTarget.setAttribute("required", "true")
  }

  hide() {
    const dsfrElt = window.dsfr(this.dependentInputWrapperTarget)
    if (dsfrElt) {
      window.dsfr(this.dependentInputWrapperTarget).collapse.conceal()
    } else {
      // parfois au chargement de la page dsfrElt est null 🤷
      this.dependentInputWrapperTarget.classList.remove("fr-collapse--expanded")
    }
    this.dependentInputTarget.setAttribute("disabled", "disabled")
  }
}
